<script language="javascript" runat="server">
/**
 * asp-xss-filter
 * @author zsx<zsx@zsxsoft.com>
 */

/**
 * XSS过滤对象
 *
 * @param {Object} options 选项：whiteList, onTag, onTagAttr, onIgnoreTag,
 *                               onIgnoreTagAttr, safeAttrValue, escapeHtml
 *                               stripIgnoreTagBody, allowCommentTag
 */
var FilterXSS = function(options) {
  /**
   * 过滤XSS
   *
   * @author 老雷<leizongmin@gmail.com>
   */

  var DEFAULT = XSS_CONFIG;
  var parser = XSS_PARSER;
  var parseTag = parser.parseTag;
  var parseAttr = parser.parseAttr;
  /**
   * 返回值是否为空
   *
   * @param {Object} obj
   * @return {Boolean}
   */
  function isNull(obj) {
    return (obj === undefined || obj === null);
  }

  /**
   * 取标签内的属性列表字符串
   *
   * @param {String} html
   * @return {Object}
   *   - {String} html
   *   - {Boolean} closing
   */
  function getAttrs(html) {
    var i = html.indexOf(' ');
    if (i === -1) {
      return {
        html: '',
        closing: (html.substr(html.length - 2, 1) === '/')
      };
    }
    html = html.slice(i + 1, -1).replace(/(^\s*)|(\s*$)/g, "");
    var isClosing = (html.substr(html.length - 1, 1) === '/');
    if (isClosing) html = html.slice(0, -1).replace(/(^\s*)|(\s*$)/g, "");
    return {
      html: html,
      closing: isClosing
    };
  }


  options = options || {};

  if (options.stripIgnoreTag) {
    if (options.onIgnoreTag) {
      //console.error('Notes: cannot use these two options "stripIgnoreTag" and "onIgnoreTag" at the same time');
    }
    options.onIgnoreTag = DEFAULT.onIgnoreTagStripAll;
  }

  options.whiteList = options.whiteList || DEFAULT.whiteList;
  options.onTag = options.onTag || DEFAULT.onTag;
  options.onTagAttr = options.onTagAttr || DEFAULT.onTagAttr;
  options.onIgnoreTag = options.onIgnoreTag || DEFAULT.onIgnoreTag;
  options.onIgnoreTagAttr = options.onIgnoreTagAttr || DEFAULT.onIgnoreTagAttr;
  options.safeAttrValue = options.safeAttrValue || DEFAULT.safeAttrValue;
  options.escapeHtml = options.escapeHtml || DEFAULT.escapeHtml;
  options.allowCommentTag = (typeof(options.allowCommentTag) != 'undefined' ? options.allowCommentTag : DEFAULT.allowCommentTag);
  //this.options = options;
  return {
    options: options,
    /**
     * 开始处理
     *
     * @param {String} html
     * @return {String}
     */
    process: function(html) {
      // 兼容各种奇葩输入
      html = html || '';
      html = html.toString();
      if (!html) return '';

      var me = this;
      var options = me.options;
      var whiteList = options.whiteList;
      var onTag = options.onTag;
      var onIgnoreTag = options.onIgnoreTag;
      var onTagAttr = options.onTagAttr;
      var onIgnoreTagAttr = options.onIgnoreTagAttr;
      var safeAttrValue = options.safeAttrValue;
      var escapeHtml = options.escapeHtml

      // 是否禁止备注标签
      if (!options.allowCommentTag) {
        html = DEFAULT.stripCommentTag(html);
      }

      // 如果开启了stripIgnoreTagBody
      if (options.stripIgnoreTagBody) {
        var stripIgnoreTagBody = DEFAULT.StripTagBody(options.stripIgnoreTagBody, onIgnoreTag);
        onIgnoreTag = stripIgnoreTagBody.onIgnoreTag;
      } else {
        stripIgnoreTagBody = false;
      }

      var retHtml = parseTag(html, function(sourcePosition, position, tag, html, isClosing) {
        var info = {
          sourcePosition: sourcePosition,
          position: position,
          isClosing: isClosing,
          isWhite: (tag in whiteList)
        };

        // 调用onTag处理
        var ret = onTag(tag, html, info);
        if (!isNull(ret)) return ret;

        // 默认标签处理方法
        if (info.isWhite) {
          // 白名单标签，解析标签属性
          // 如果是闭合标签，则不需要解析属性
          if (info.isClosing) {
            return '</' + tag + '>';
          }

          var attrs = getAttrs(html);
          var whiteAttrList = whiteList[tag];
          var attrsHtml = parseAttr(attrs.html, function(name, value) {

            // 调用onTagAttr处理
            var isWhiteAttr = (function (name) {
              for (var i = 0; i < whiteAttrList.length; i++) {
                if (whiteAttrList[i] == name) return true;
              }
              return false;
            })(name);
            var ret = onTagAttr(tag, name, value, isWhiteAttr);
            if (!isNull(ret)) return ret;

            // 默认的属性处理方法
            if (isWhiteAttr) {
              // 白名单属性，调用safeAttrValue过滤属性值
              value = safeAttrValue(tag, name, value);
              if (value) {
                return name + '="' + value + '"';
              } else {
                return name;
              }
            } else {
              // 非白名单属性，调用onIgnoreTagAttr处理
              var ret = onIgnoreTagAttr(tag, name, value, isWhiteAttr);
              if (!isNull(ret)) return ret;
              return;
            }
          });

          // 构造新的标签代码
          var html = '<' + tag;
          if (attrsHtml) html += ' ' + attrsHtml;
          if (attrs.closing) html += ' /';
          html += '>';
          return html;

        } else {
          // 非白名单标签，调用onIgnoreTag处理
          var ret = onIgnoreTag(tag, html, info);
          if (!isNull(ret)) return ret;
          return escapeHtml(html);
        }

      }, escapeHtml);

      // 如果开启了stripIgnoreTagBody，需要对结果再进行处理
      if (stripIgnoreTagBody) {
        retHtml = stripIgnoreTagBody.remove(retHtml);
      }

      return retHtml;

    }
  }
}


</script>