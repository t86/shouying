/*
 * @Description:
 * @Author: tanglin tanglin19811@gmail.com
 * @Date: 2023-04-06 16:37:30
 * @LastEditors: tanglin tanglin19811@gmail.com
 * @LastEditTime: 2023-04-06 16:44:32
 */
import { Message } from "element-ui";
export const copyToClipboard = async (text) => {
  if (typeof text == "undefined") {
    Message({
      message: "复制内容为空",
      type: "warning",
    });
    return;
  }
  function authentication() {
    if ("clipboard" in navigator) {
      return new Promise((resolve, reject) => {
        navigator.permissions.query({ name: "clipboard-read" }).then(
          (result) => {
            if (result.state == "granted" || result.state == "prompt") {
              resolve(true);
            } else {
              resolve(false);
            }
          },
          (error) => {
            reject(error);
          }
        );
      });
    } else {
      Message({
        message: "该浏览器暂不支持，请使用最新版本的GoogleChrome浏览",
        type: "error",
      });
      return Promise.resolve(false);
    }
  }
  let res = await authentication();
  if (res) {
    navigator.clipboard.writeText(text).then(
      () => {
        Message({
          message: "复制成功",
          type: "success",
        });
      },
      () => {
        Message({
          message: "复制失败",
          type: "error",
        });
      }
    );
  }
};
