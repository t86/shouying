/**
 * 全局方法
 */

// 判断字符串字符长度
function character(v) {
  // console.log(v.length);
  var len = 0
  for (var i = 0; i < v.length; i++) {
    if (v.charCodeAt(i) > 127 || v.charCodeAt(i) == 94) {
      len += 2
    } else {
      len++
    }
    // if(i == v.length-1){
    //     console.log(v.charCodeAt(i));
    // }
  }

  // console.log(len);
  return len
}

// 获取uuid
function generateUUID() {
  var d = new Date().getTime();
  if (window.performance && typeof window.performance.now === "function") {
    d += performance.now(); //use high-precision timer if available
  }
  var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
    var r = (d + Math.random() * 16) % 16 | 0;
    d = Math.floor(d / 16);
    return (c == 'x' ? r : (r & 0x3 | 0x8)).toString(16);
  });
  return uuid;
}

// hex转rgba
function hex2Rgb(bgColor, alpha = 1) {
  let color = bgColor.slice(1); // 去掉'#'号
  let rgb = [
    parseInt("0x" + color.slice(0, 2)),
    parseInt("0x" + color.slice(2, 4)),
    parseInt("0x" + color.slice(4, 6)),
  ];
  return rgb;
}


function Rgb2hex(value) {
  if (/rgba?/.test(value)) {
    var array = value.split(",");
    //不符合rgb或rgb规则直接return
    if (array.length < 3)
      return "";
    value = "#";
    for (var i = 0, color; color = array[i++];) {
      if(i < 4){
        //前三位转换成16进制
        color = parseInt(color.replace(/[^\d]/gi, ''), 10).toString(16);
        value += color.length == 1 ? "0" + color : color;
      }else{
        //rgba的透明度转换成16进制
        color = color.replace(')', '')
        var colorA = parseInt(color*255);
        var colorAHex = colorA.toString(16);
        value += colorAHex;
      }
    }
    value = value.toUpperCase();
  }
  return  value;
}

function toFixed(num,decimal) {
	num = num.toString();
	let index = num.indexOf('.');
	if (index !== -1) {
		num = num.substring(0, decimal + index + 1)
	} else {
		num = num.substring(0)
	}
	return parseFloat(num).toFixed(decimal)
}

export default {character, generateUUID, hex2Rgb, Rgb2hex, toFixed}