import base from "@/api/base";
import api_card from "@/api/Book";
import { resResultDataArr } from "@/utils/config/card";
import { transformCardDataHandle } from "@/utils/transformCardData";
import { localStorage } from "@/utils/common/storage";
import eventVue from "@/utils/eventVue";
import api_auth from "@/api/UtilAuth";
import { CODE_INVALID } from "@/observer";

let keys = {
  9: ["prdId", "grpId", "seqId"],
  12: ["stationId", "authType", "twoCateId"],
  15: ["station_id", "region_id"],
  16: ["region_id", "prd_id"],
  21: ["two_cate_id", "rqm_type_id"],
  27: ["station_id", "prd_id"],
  36: ["station_id", "auth_type", "free_limit_id"],
  37: ["free_limit_id", "prd_id"],
  39: ["id", "region_id"],
  40: ["license_id", "type_id", "region_o_seat_id"],
};
export default class WebSocketClient {
  constructor(vue) {
    this.vue = vue;
    this.res = { code: 1 };
    this.initAllData = this.initAllData.bind(this);
    this.resResultDataObj =
      this.vue.$store.state.cardPageInfo.resResultDataObj || {};
    // 初始化 WebSocket 连接
    this.initAllData();
    window.addEventListener("beforeunload", (e) => this.closeHandle(e));
    this.vue.$observer.subscribe(CODE_INVALID, () => {
      this.reset();
    });
  }

  connect = () => {
    typeof WebSocket === "undefined"
      ? this.vue.$message.warning("您的浏览器不支持socket")
      : this.connectWebsocket();
  };

  connectWebsocket = () => {
    // 实例化socket
    this.socket = new WebSocket(base.cardWebsocketPath + "/sync");
    // 监听socket连接
    this.socket.onopen = this.openHandle;
    // 监听socket错误信息
    this.socket.onerror = this.errorHandle;
    // 监听socket消息
    this.socket.onmessage = this.messageHandle;
  };

  openHandle = async (e) => {
    const token = localStorage.getItem("tk") || "";
    if (token) {
      if (!localStorage.getItem("refreshAll")) {
        await this.getAllData(true, true, true);
      } else {
        await this.getUpdateData();
      }
    }

    this.socket.send(JSON.stringify(token));
    // 监听处理websocket是否断开连接
    this.websocketHasConnect();
  };

  errorHandle = (e) => {
    // console.log("websocket error：", e);
    // clearTimeout(this.errorTimer);
    // this.errorTimer = setTimeout(() => {
    this.vue.$message.warning("websocket连接失败，5s后将重新连接！");
    console.log(
      "%c websocket连接失败，5s后将重新连接！",
      "color:blue;font-size:14px"
    );
    this.closeHandle();
    this.initAllData();
    //   // 是否接收到系统返回的时间？接收到了获取增量数据，否则重新拉取全量数据
    //   this.websocketTimeMessageTime
    //     ? this.getUpdateData()
    //     : this.getAllData(true, false);
    // }, 5000);
  };

  closeHandle = (e) => {
    if (this.socket) {
      this.socket.close();
      this.socket = null;
      // this.vue.$store.commit('updateResResultDataObj', this.resResultDataObj)
      // this.socket.onclose = event => console.log('websocket已关闭')
    }
    clearTimeout(this.timeOutTimer);
    // clearTimeout(this.errorTimer);
    clearTimeout(this.isConnectedTimer);
  };

  messageHandle = async (e) => {
    console.log(e);
    const { p: code, t: time, d: data } = JSON.parse(e.data);
    // 更新接收到消息的时间
    this.websocketTimeStart = +new Date(); // code: 1:数据更新  2：无更新，保持连接不断  3：错误信息
    if (code == 1) {
      this.updateCardList(data, time);
    } else if (code == 3) {
      let message = typeof data == "string" ? data : "websocket返回数据出错";
      if (
        message === "第一个消息必须为授权信息" ||
        message === "未发现授权信息" ||
        message === "授权信息未找到或已过期"
      ) {
        this.vue.$observer.send(CODE_INVALID);
      }
      this.vue.$message.warning(message);
    } else {
      localStorage.setItem("websocketTimeMessageTime", time);
    }
  };

  reset = async () => {
    this.closeHandle();
    this.initAllData();
  };
  // 监听处理websocket是否断开
  websocketHasConnect = () => {
    // 首次加载时间
    this.websocketTimeStart = +new Date();
    const distanceTime =
      +new Date("2022/09/02 11:01:05") - +new Date("2022/09/02 11:00:00");

    const hasConnectedHandle = (time) => {
      this.isConnectedTimer = setTimeout(() => {
        // console.log('是否断开', (+new Date() - this.websocketTimeStart) > distanceTime);
        if (+new Date() - this.websocketTimeStart > distanceTime) {
          // 已断开连接
          this.vue.$message.warning("检测到websocket已断开，即将重新连接！");
          console.log(
            "%c检测到websocket已断开，即将重新连接！",
            "color:blue;font-size:14px"
          );
          this.closeHandle();
          this.initAllData();
          // // 是否接收到系统返回的时间？接收到了获取增量数据，否则重新拉取全量数据
          // this.websocketTimeMessageTime
          //   ? this.getUpdateData()
          //   : this.getAllData(true, false);
        } else {
          hasConnectedHandle(60000);
        }
      }, time);
    };

    clearTimeout(this.isConnectedTimer);
    // 首次间隔65s
    // 其后间隔60m，与后端保持一致（心跳检测）
    hasConnectedHandle(65000);
  };

  getAllData = async (loadCard = false, reload = false, init = false) => {
    console.log("%c begin", "color:red;font-size:14px");
    console.log("reload", reload);
    console.log("this.res", JSON.parse(JSON.stringify(this.res)));
    this.resResultDataObj =
      this.vue.$store.state.cardPageInfo.resResultDataObj || {};
    // 是否需要重新请求元素据
    const needReloadData =
      reload ||
      !(this.resResultDataObj && this.resResultDataObj.areaInfo) ||
      !localStorage.getItem("websocketTimeMessageTime");
    try {
      let res = {};
      if (reload || this.res.code != 1) {
        res = needReloadData ? await api_card.reqGetAllData() : { code: 1 };
        this.res = JSON.parse(JSON.stringify(res));
      } else {
        res = JSON.parse(JSON.stringify(this.res));
      }
      if (res.code == 1 || res.code == 2) {
        this.websocketTimeMessageTime = res.data.ts
          ? res.data.ts
          : this.websocketTimeMessageTime;
      }
      if (res.code == 1) {
        if (needReloadData) {
          this.resResultDataObj = {};

          let data = res.data ? res.data.ds : [];
          localStorage.setItem("refreshAll", ...data["23"]);
          localStorage.setItem("websocketTimeMessageTime", res.data.ts);
          resResultDataArr.forEach((el, index) => {
            this.resResultDataObj[el] =
              el != "businessData"
                ? transformCardDataHandle(data[index], index)
                : transformCardDataHandle(data[index], index).filter(
                    (item) => item.bizStatus != 22 && item.bizStatus != 33
                  );
          });

          // // 获取设备可操作区域或卡台
          // const currentMachineId = this.vue.$localStorage.getItem("machineId");
          // const currentAreaAndCardList = (
          //   this.resResultDataObj["machineArea"] || []
          // ).filter(
          //   (item) => item.license_id == currentMachineId && item.status == 1
          // );
          // const isNoLimit = currentAreaAndCardList.filter(
          //   (item) => item.type_id == 3
          // );
          // if (isNoLimit.length <= 0) {
          //   // 有限制
          //   const areaList = currentAreaAndCardList.filter(
          //     (item) => item.type_id == 1
          //   );
          //   const cardList = currentAreaAndCardList.filter(
          //     (item) => item.type_id == 2
          //   );
          //   // 当前配置的区域id
          //   let areaIdList = areaList.map((item) => item.region_o_seat_id);

          //   // 通过cardList反推出对应的区域，并添加到区域id中
          //   const allCardInfo = [...this.resResultDataObj.cardInfo] || [];

          //   // 最终经过筛选过后的区域列表，对应元数据的areaInfo
          //   let resultAreaList = [];
          //   // 最终经过筛选过后的卡台列表，对应元数据的cardInfo
          //   let resultCardList = [];

          //   areaIdList.forEach((el) => {
          //     // 存储配置区域的区域下所有卡台
          //     const currentAreaCardList = allCardInfo.filter(
          //       (item) => item.regionId == el
          //     );
          //     resultCardList = [...resultCardList, ...currentAreaCardList];
          //   });

          //   cardList.forEach((el) => {
          //     const find = allCardInfo.find(
          //       (item) => item.id == el.region_o_seat_id
          //     );
          //     if (find) {
          //       resultCardList.push(find);
          //       if (!areaIdList.find((item) => item == find.regionId)) {
          //         areaIdList.push(find.regionId);
          //       }
          //     }
          //   });

          //   const allAreaInfo = [...this.resResultDataObj.areaInfo] || [];
          //   areaIdList.forEach((el) => {
          //     const find = allAreaInfo.find((item) => item.id == el);
          //     resultAreaList.push(find);
          //   });
          //   this.resResultDataObj.areaInfo = resultAreaList.map((item) => ({
          //     ...item,
          //     isAllCard: !!areaList
          //       .map((item) => item.region_o_seat_id)
          //       .find((items) => items == item.id), // 是否是配置的可可显示的区域（如果配置的区域，则展现出的卡台为当前区域下所有卡台，否则为部分卡台，即通过部分卡台反推出来的区域）
          //   }));
          //   this.resResultDataObj.cardInfo = resultCardList;
          // }

          console.log("new-resResultDataObj:", this.resResultDataObj);

          this.vue.$store.commit(
            "updateResResultDataObj",
            this.resResultDataObj
          );
          this.vue.$store.commit(
            "updateStoreStatusId",
            this.resResultDataObj["storeStatusInfo"][0]["wkday_id"]
          );
        } else {
          if (init) this.getUpdateData();
          console.log("old-resResultDataObj:", this.resResultDataObj);
        }

        if (loadCard) {
          if (
            this.vue.$route.name == "cardMachine" ||
            this.vue.$route.name == "orderCard" ||
            this.vue.$route.name == "moneyCard"
          ) {
            // 加载卡台相关数据
            // const getTabShowCount = this.vue.$children[0].getTabShowCount
            // const getAllData = this.vue.$children[0].getAllData

            // if (getTabShowCount && getAllData) getTabShowCount(getAllData);

            // this.vue.$children[0].showOrHideModelVisible && this.vue.$children[0].showOrHideModelVisible();

            eventVue.$emit("reloadData", { func: this.getAllData, hide: true });
          } else {
            // 更新本地store和sessionStorage中存储的卡台信息
            this.updateTabListData(this.resResultDataObj["areaInfo"]);
            this.updateCardListData(
              this.resResultDataObj["cardInfo"],
              this.resResultDataObj["businessData"]
            );
            if (this.resResultDataObj["storeStatusInfo"][0]["wkday_id"] == 0) {
              if (this.vue.$route.name !== "Thelogin") {
                this.vue.$message.warning("营业日已关闭，即将返回登录页面");
                setTimeout(this.logoutHandle, 1000);
              }
            }
          }
        }
      }
    } catch (error) {
      console.log("全量数据请求失败", error);
    }
  };

  // 退出登录
  async logoutHandle() {
    try {
      const res = await api_auth.auth.requestauthlogout();
      if (res.code === 1) {
        // this.vue.$store.commit("updateResResultDataObj", "");
        this.vue.$store.commit("updateUserInfo", "");
        this.vue.$router.replace({
          name: "Thelogin",
          replace: true,
          query: {
            client: this.vue.$store.state.client,
          },
        });
      } else {
        this.vue.$message.warning(res.msg);
      }
    } catch (error) {
      console.log("logout失败", error);
    }
  }

  // 获取websocket断开期间的增量数据
  getUpdateData = async () => {
    this.websocketTimeMessageTime =
      localStorage.getItem("websocketTimeMessageTime") || "";
    if (!this.websocketTimeMessageTime) return;
    const params = {
      // '20220902171731'//
      last_sync_time: this.websocketTimeMessageTime, // string     //LastSyncTime 上次完成同步时间,建议往回走个30秒, 格式 yyyymmddhh24miss
    };
    try {
      const res = await api_card.reqGetUpdateData(params);
      // 更新接收到消息的时间
      this.websocketTimeStart = +new Date();

      const data = res.data || {};
      if (res.code == 1 || res.code == 2) {
        this.websocketTimeMessageTime = data.ts
          ? data.ts
          : this.websocketTimeMessageTime;
      }

      if (res.code === 1) {
        this.updateCardList(data.ds || [], this.websocketTimeMessageTime);
      } else {
        this.vue.$message.warning(res.msg);
      }
    } catch (error) {
      console.log("获取websocket断开期间的增量数据失败", error);
    }
  };

  // websocket数据更新
  updateCardList = (dataObj = {}, time = "") => {
    for (let key in dataObj) {
      // 开启营业日的时候，业务数据为空，需要重新赋值业务数据
      if (
        key == 14 &&
        this.resResultDataObj[resResultDataArr[key]].length == 0
      ) {
        console.log(1, "key", key);
        return this.getAllData(true, false);
      } else if (key == 18) {
        // 判断营业日id状态是否发生变化，变化的话重新获取业务数据
        this.vue.$store.commit("updateStoreStatusId", dataObj[key][0][0]);
        console.log(2, "key", key);
        eventVue.$emit("reloadData");
        return this.getAllData(true, true);
      } else if (key == 22) {
        // 收银系统卡台页面小红点数量发生变化
        this.vue.$store.commit(
          "updateMoneyCardNeedBackOrderCount",
          dataObj[key][0][0]
        );
      } else if (key == 23) {
        console.log(3, "key", key);
        let version = localStorage.getItem("refreshAll");
        if (version && version != dataObj[key][0] * 1) {
          localStorage.setItem("refreshAll", ...dataObj[key]);
          // 页面需要从新获取最新全量数据
          return this.getAllData(true, true);
        }
      } else {
        dataObj[key] = transformCardDataHandle(dataObj[key], key);
        dataObj[key].forEach((el) => {
          // console.log(`websocket改变详情:`, el);  // TODO:
          // 查找当前改变的数据下标索引值
          const index = this.resResultDataObj[resResultDataArr[key]].findIndex(
            (ele) => {
              if (key in keys) {
                let match = true;
                let values = keys[key];
                for (let i = 0; i < values.length; i++) {
                  if (ele[values[i]] !== el[values[i]]) {
                    match = false;
                    break;
                  }
                }
                return match;
              }

              if (Number(key) <= 8) {
                // 数据id字段名称为id
                return ele.id == el.id;
              } else if (Number(key) <= 10) {
                // 数据id字段为prdId
                return ele.prdId == el.prdId;
              } else if (Number(key) <= 12) {
                // 数据id字段为stationId
                return ele.stationId == el.stationId;
              } else if (Number(key) == 13) {
                // 数据字段为station_id
                return ele.station_id == el.station_id;
              } else if (Number(key) == 14) {
                // 数据id字段为seatId
                return ele.seatId == el.seatId;
              } else if (Number(key) == 15) {
                // 数据id字段为station_id
                return ele.station_id == el.station_id;
              } else if (Number(key) == 16) {
                // 数据id字段为region_id
                return ele.region_id == el.region_id;
              } else if (Number(key) <= 20) {
                // 数据id字段为id
                return ele.id == el.id;
              } else if (Number(key) == 21) {
                // 数据id字段为rqm_type_id
                return ele.rqm_type_id == el.rqm_type_id;
              } else if (Number(key) == 24) {
                //  咨客可操作日期列表
                return ele.id == el.id;
              } else if (Number(key) == 25) {
                //  未来(当日以后的)预留业务数据
                return (
                  ele.seat_id == el.seat_id &&
                  ele.book_day_value == el.book_day_value
                );
              } else if (Number(key) == 26) {
                // 线上卡台标记
                return ele.seat_id == el.seat_id;
              } else if (Number(key) == 27) {
                // 角色关联花篮,小费商品权限
                return ele.station_id == el.station_id;
              } else if (Number(key) <= 29) {
                return ele.seat_id == el.seat_id;
              } else if (Number(key) <= 35) {
                return ele.id == el.id;
              } else if (Number(key) == 36) {
                return ele.station_id == el.station_id;
              } else if (Number(key) == 37) {
                return ele.free_limit_id == el.free_limit_id;
              } else if (Number(key) == 39) {
                // 卡台状态数量统计
                return ele.id == el.id && ele.region_id == el.region_id;
              }
            }
          );

          if (key == 38) {
            // 商户号收款金额汇总
            this.resResultDataObj[resResultDataArr[key]][0] = el;
          }

          if (index < 0 && (key == 39 || key == 35)) {
            // 新增卡台状态数量统计
            console.log("5", key, el);
            // return this.getAllData(true, true)
          }

          if (index < 0) {
            this.resResultDataObj[resResultDataArr[key]][
              this.resResultDataObj[resResultDataArr[key]].length
            ] = el;
          } else {
            if (key in keys) {
              let stId = this.resResultDataObj[resResultDataArr[key]][index];
              let elements = this.resResultDataObj[
                resResultDataArr[key]
              ].filter((e) => {
                let match = true;
                let values = keys[key];
                for (let i = 0; i < values.length; i++) {
                  if (e[values[i]] !== stId[values[i]]) {
                    match = false;
                    break;
                  }
                }
                return match;
              });
              if (elements.length > 0) {
                Object.assign(elements[0], el); // 拷贝属性到目标对象
              } else {
                this.resResultDataObj[resResultDataArr[key]][
                  this.resResultDataObj[resResultDataArr[key]].length
                ] = el;
              }
            } else {
              this.resResultDataObj[resResultDataArr[key]][index] = el;
            }
          }

          // 刷新收银系统订单数据
          if (
            this.vue.$route.name == "payOrder" &&
            key * 1 == 14 &&
            this.vue.$store.state.orderInfo.currentCardInfo &&
            dataObj[key].some(
              (item) =>
                item.seatId ==
                this.vue.$store.state.orderInfo.currentCardInfo.seatId
            )
          ) {
            eventVue.$emit("reloadPayOrderList");
          }
        });
      }
    }

    this.vue.$store.commit("updateResResultDataObj", this.resResultDataObj);
    if (
      this.vue.$route.name == "cardMachine" ||
      this.vue.$route.name == "orderCard" ||
      this.vue.$route.name == "moneyCard"
    ) {
      eventVue.$emit("reloadData");
      // this.vue.$children[0] && this.vue.$children[0].getTabList && this.vue.$children[0].getTabList(this.resResultDataObj['areaInfo'])
      // this.vue.$children[0] && this.vue.$children[0].getCardList && this.vue.$children[0].getCardList(this.resResultDataObj['cardInfo'], this.resResultDataObj['businessData'])
    } else {
      // 更新本地store和sessionStorage中存储的卡台信息
      this.updateTabListData(this.resResultDataObj["areaInfo"]);
      this.updateCardListData(
        this.resResultDataObj["cardInfo"],
        this.resResultDataObj["businessData"]
      );
    }

    if (time) localStorage.setItem("websocketTimeMessageTime", time);
  };

  // 更新修改后的tab数据
  updateTabListData = (arr = []) => {
    arr = arr.sort((a, b) => Number(a.dsp) - Number(b.dsp));
    let tabList = arr.filter((el) => el.status == "1"); // status:  1:有效 2:无效
    this.vue.$store.commit("updateTabList", tabList);
  };

  // 更新修改后的card数据
  updateCardListData = (cardInfo = [], businessData = []) => {
    // cardInfo:卡台数据  businessData:业务数据
    cardInfo = cardInfo.sort((a, b) => a.name.localeCompare(b.name));
    const cardList = [];
    cardInfo.forEach((item, index) => {
      if (item.status == "1") {
        // 查找对应的业务数据
        const data = businessData.find((el) => el.seatId == item.id) || [];
        if (data.bizStatus != "22" && data.bizStatus != "33") {
          cardList.push({
            // 卡台数据
            ...item,
            // 业务数据
            ...data,
            // 赠送金额
            zengSongAmt: (Number(data.yhAmt) + Number(data.yh2Amt)).toFixed(2),
            // 抵消进度
            diXiaoJindu:
              Number(data.assignMinCsmAmt) > 0 && data.openType == 1
                ? (
                    Number(data.orderAmt) / Number(data.assignMinCsmAmt)
                  ).toFixed(0) > 1
                  ? "100%"
                  : (
                      (Number(data.orderAmt) / Number(data.assignMinCsmAmt)) *
                      100
                    ).toFixed(0) + "%"
                : "",
          });
        }
      }
    });

    this.vue.$store.commit("updateCardList", cardList);
  };

  initAllData() {
    clearTimeout(this.timeOutTimer);
    this.timeOutTimer = setTimeout(() => {
      if (this.vue.$route.name == "register") {
        setTimeout(() => {
          this.closeHandle();
          this.initAllData();
        }, 1000);

        return;
      }

      const token = localStorage.getItem("tk") || "";
      if (token) {
        // 不是订单，收银，预定系统，不需要websocket
        if (
          sessionStorage.getItem("client") == "money" ||
          sessionStorage.getItem("client") == "order" ||
          sessionStorage.getItem("client") == "book"
        ) {
          this.connect();
          return;
        }
      }
      this.initAllData();
    }, 100);
  }
}
