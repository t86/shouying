// 金额添加千分位
export const comdify = function (n) {
  if (!n) return n;
  let str = n.split(".");
  let re = /\d{1,3}(?=(\d{3})+$)/g;
  let n1 = str[0].replace(re, "$&,");
  return str.length > 1 && str[1] ? `${n1}.${str[1]}` : `${n1}`;
};
//去除千分位中的‘，’
export const delcommafy = function (num) {
  if (!num) return num;
  num = num.toString();
  num = num.replace(/,/gi, "");
  return num;
};
export const valdateFn = function (rule, val, cb) {
  setTimeout(() => {
    if (val) {
      let inputVal = delcommafy(val);
      if (rule.test(inputVal)) {
        cb();
      } else {
        cb("只能是数字,最多两位小数");
      }
    }
    cb();
  });
};
// 验证金额数字可以为负数
export const moneyValid = function (rule, val, cb) {
  valdateFn(/((^-?[1-9]\d*)|^-?0)(\.\d{0,2}){0,1}$/, val, cb);
};
// 验证金额数字不可以为负数
export const moneyNValid = function (rule, val, cb) {
  valdateFn(MoneyTest, val, cb);
};

// 获取输入框的值
export const getInputValue = function (el) {
  let inputVal = el.target.value || "";
  if (delcommafy) return comdify(delcommafy(inputVal));
};
/** 格式化数字，不足长度时补0 */
export const formatVal = function (val, formatLen) {
  val = val + "";
  for (var i = val.length; i < formatLen; i++) {
    val = "0" + val;
  }
  return val;
};
/** 限制只能输入正整数 */
export const inputLimitPositiveNum = (numStr) => {
  numStr = numStr.replace(/^(\d+)$/, "$1");
  numStr = numStr.replace(/[\u4e00-\u9fa5]+/g, ""); //清除汉字
  numStr = numStr.replace(/[^\d]/g, ""); //清楚非数字
  numStr = numStr.replace(/^\./g, ""); //验证第一个字符是数字而不是
  return numStr;
};
/** 限制只能输入-+数字+.后2位 */
export const inputLimitNum = (numStr) => {
  numStr = numStr.replace(/^(\-)?(\d+)(\.\d{2}).*$/, "$1$2$3");
  numStr = numStr.replace(/[\u4e00-\u9fa5]+/g, ""); //清除汉字
  numStr = numStr.replace(/[^-\d.]/g, ""); //清楚非数字和小数点
  numStr = numStr.replace(/^\./g, ""); //验证第一个字符是数字而不是
  numStr = numStr.replace(".", "$#$").replace(/\./g, "").replace("$#$", "."); //只保留第一个小数点, 清除多余的
  return numStr;
};
/** 限制只能输入数字以及小数2位
 * @param length 限制小数位长度
 */
export const inputLimitDecimal = (numStr, length = 2) => {
  let re = new RegExp("^(\\-)?(\\d+)(\\.\\d{" + length + "}).*$", "g");
  numStr = numStr.replace(re, "$1$2$3");
  // numStr = numStr.replace(/^(\-)?(\d+)(\.\d{2}).*$/, '$1$2$3');
  numStr = numStr.replace(/[\u4e00-\u9fa5]+/g, ""); //清除汉字
  numStr = numStr.replace(/[^\d.]/g, ""); //清楚非数字和小数点
  numStr = numStr.replace(".", "$#$").replace(/\./g, "").replace("$#$", "."); //只保留第一个小数点, 清除多余的
  return numStr;
};
/** 判断是否为空 */
export const isEmpty = (str, minLength, maxLength) => {
  str = str.toString();
  minLength = minLength ? minLength : 1;
  maxLength = maxLength ? maxLength : 99999999;
  if (
    str == null ||
    str.trim().length < minLength ||
    str.trim().length > maxLength
  ) {
    return true;
  }
  return false;
};
/** 补 0 */
export const add0 = (m) => {
  return m < 10 ? "0" + m : m;
};
//处理直接输入.
export const formatPointNumber = (val) => {
  let value = val;
  if (!value || value.length == 0) {
    return "";
  }

  let str = value[0];
  if (str == ".") {
    if (value.length == 1) {
      value = "0";
    } else {
      value = "0" + value;
    }
  }
  return value;
};
export const formatNumber = (val) => {
  let value = val;
  if (!value || value.length == 0) {
    return "";
  }

  let str = value[0];
  if (str == ".") {
    if (value.length == 1) {
      value = "0";
    } else {
      value = "0" + value;
    }
  }
  return value;
};
