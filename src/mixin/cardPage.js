// 卡台列表相关重复操作的函数（cardMachine.vue  moneyCard.vue   orderCard.vue）

import api_auth from "@/api/UtilAuth";
import api_order from "@/api/order";
import md5 from "js-md5";
import eventVue from "@/utils/eventVue";

export const cardPageMixins = {
  methods: {

    // 根据当前用户角色，权限，设备限制等判断条件获取区域及卡台列表
    getAreaAndCardList(){
      const areaAndCardListType = [
        {
          id: "区域id", // 0 全部 2001 我的 一般的区域id
          all: "0 or 1", // 0 非全区域 1 全区域
          showCardList: { 
            "卡台id": true, 
          },
          noAmountCardList:{  // 显示金额卡台id列表
            '卡台id' : true
          }
    /* 
      1.根据设备限制判断区域是否满足all为1 等，先过滤出第一波区域卡台信息
      2.根据角色权限过滤区域和卡台
          服务员
          一、默认权限：允许查看下属点单消费 不能查看同组点单消费金额
            可以查看所有卡台，但不能查看同组点单消费金额等信息,可以查看自己以及下属卡台的消费金额
            开台，抵达等信息不受影响
            区域all设置为1，showCardList设置为0，把不能看金额的卡台加入noAmountCardList
            或者区域all设置为0，showCardList罗列卡台，把不能看金额的卡台加入noAmountCardList
          二、不允许查看下属点单消费 
            区域all设置为1，showCardList设置为0，把不能看金额的卡台加入noAmountCardList
            或者区域all设置为0，showCardList罗列卡台，把不能看金额的卡台加入noAmountCardList
          三、查看同组点单消费
            区域all设置为1，showCardList设置为0，把不能看金额的卡台加入noAmountCardList
            或者区域all设置为0，showCardList罗列卡台，把不能看金额的卡台加入noAmountCardList
          特饮实现和服务员一 一样的效果
          督查可以查看全场，具体卡台根据设备限制来
            区域all设置为1，showCardList设置为0，或者区域all设置为0，showCardList罗列卡台
          
          营销 （营销关注订位， 服务员关注点单），营销不会使用noAmountCardList
            一、 默认权限：不能查看同组，不能优惠查看全场，只能看到下属以及自己订位的卡台
              区域all设置为1，showCardList设置为0，
              或者区域all设置为0，showCardList罗列卡台，
            二、查看和优惠全场
              区域all设置为1，showCardList设置为0
              或者区域all设置为0，showCardList罗列卡台
            三、不允许查看和优惠下属订位卡台
              区域all设置为1，showCardList设置为0
              或者区域all设置为0，showCardList罗列卡台
            四、查看和优惠同组订位卡台
              区域all设置为1，showCardList设置为0
              或者区域all设置为0，showCardList罗列卡台

          既是服务员又是营销，取两者的并集，显示最大可查看权限
              
      当 all为1时，该区域下卡台为空，从元数据cardInfo根据区域id获取匹配卡台列表，
      从元数据cardStatusNo获取每个区域的卡台状态，开台数和抵达数需要通过30，31数据来获取，
      基于现有数据接口，不支持从卡台id倒查区域id(cardInfo时数组，不够高效)，可以在store里添加一个数据映射卡台id到区域id，提高查询速度
      当 all为0时，从元数据businessData获取每个卡台状态，累计开台和抵达数由于涉及历史数据,
      还是需要从元数据cardStatusNo的30，31数据来获取

    */

        }
      ]

    },

    // 切换tab
    changeTab(index, id) {
      if (this.modelVisible) return;
      if (id === 999) {
        // 点击的是其它这个按钮本身
        this.tab.showAnotherInfo = !this.tab.showAnotherInfo;
      } else {
        this.keyWord = "";
        // 点击了其它按钮的兄弟元素
        this.tab.showAnotherInfo = false;
        this.card.cardList = this.filterCardList("regionId", id);
      }
      if (index > this.tab.tabMaxCount) {
        // 点击了其它按钮中的子选项  index:9999
        index = this.tab.tabMaxCount - 1;
        this.tab.anotherInfoActiveId = id;
        this.tab.showAnotherInfo = false;
      } else if (!this.tab.showAnotherInfo) {
        // 点击了其它按钮的兄弟元素
        this.tab.anotherInfoActiveId = 0;
      }
      this.tab.activeIndex = id;
      this.legendActive = 0;
    },


    // 卡台名称动态计算字体大小
    fontSize(item,index) {
      if (item && this.$refs.cardRef && this.$refs.cardRef[index] &&
        item.name != this.$refs.cardRef[index].innerText) {
          this.$refs.cardRef[index].innerText = item.name;
      }
      if (item.fontSize) return item.fontSize;
      if ((!index && index != 0) || index < 0 || !this.$refs.cardRef || !this.$refs.cardRef[index]) return
      let fontSize = 30
      this.$refs.cardRef[index].style.fontSize = fontSize + 'px';
      while (this.$refs.cardRef[index].scrollWidth > 130) {
        fontSize *= 0.95;
        this.$refs.cardRef[index].style.fontSize = fontSize + 'px';
      }
      item.fontSize = fontSize;
      // 根据当前宽度和基准宽度比例缩放
      return item.fontSize;
    },

    // 获取当前卡台的不同颜色提示小字
    /**
     * @params{
     *  status: 业务状态 1 空台 2 锁定 8 预订 4 开台 5 点单未结账 6 部分结账 7 已结账 22 无效 33 删除
     *  type:   开台类型 0 未开台 1 消费 2 内招 3 外招 4 气氛 5 全转 6 半转
     * }
     */
    getTips(status = 1, type = 0) {
      const resultArr = [];
      const originData = ["未", "消", "内", "外", "气", "全", "半"];
      // 锁台
      if (status.toString() === "2") {
        resultArr.push("锁");
        return resultArr;
      }
      // 正常情况
      if (type.toString() !== "0" && type.toString() !== "1")
        resultArr.push(originData[type]);

      return resultArr; // 显示范围：['锁', '内', '外', '气', '全', '半']
    },

    // 手动滚动翻页
    pageScroll(direction) {
      const containDom = this.$refs.containRef;
      const contentDom = this.$refs.containContentRef;
      const pageHeight = contentDom.getBoundingClientRect().height;
      const clientHeight = containDom.getBoundingClientRect().height;
      const currentScrollTop = containDom.scrollTop;
      const maxScrollTop = Math.max(pageHeight - clientHeight, 0);
      const targetScrollTop =
        direction === "down"
          ? Math.min(currentScrollTop + clientHeight, maxScrollTop)
          : Math.max(0, currentScrollTop - clientHeight);
      if (targetScrollTop === currentScrollTop) return;
      const perDistant = clientHeight / 8;
      let count = 8;
      const scrollTimer = setInterval(() => {
        count--;
        containDom.scrollTo(
          0,
          direction === "down"
            ? targetScrollTop - perDistant * count
            : targetScrollTop + perDistant * count
        );
        if (count === 0) clearInterval(scrollTimer);
      }, 25);
    },

    // 页面可视区域尺寸发生变化
    windowResizeHandle() {
      if(!this.$store.state.cardPageInfo.resResultDataObj["areaInfo"]){
        this.logOutHandle();
      }
      this.getTabShowCount();
      this.getTabList(
        JSON.parse(JSON.stringify(this.$store.state.cardPageInfo.resResultDataObj["areaInfo"]))
      );
      // 此延时器为了解决苹果iPad中，竖向使用时，scrollTop达到最大，突然转到横向，横向无法滚动到超出自己最大的scrollTop位置的问题，而出现白屏问题
      setTimeout(() => {
        const pageHeight = document.body.clientHeight;
        const clientHeight = window.innerHeight;
        const currentScrollTop =
          document.documentElement.scrollTop ||
          window.pageYOffset ||
          document.body.scrollTop;
        const maxScrollTop = Math.max(pageHeight - clientHeight, 0);
        if (currentScrollTop > maxScrollTop) window.scrollTo(0, maxScrollTop);
      }, 500);
    },

    // 鼠标按下效果
    keyDownHandle(status = "") {
      if (this.modelVisible) return;
      this.arrowStatus = status;
      if (status === "up" || status === "down") {
        this.pageScroll(status);
      } else if (status === "reload") {
        // this.legendActive = 0;
        // this.tab.activeIndex = 0;
        // this.tab.showAnotherInfo = false;
        // this.getTabShowCount(this.getAllData);
        this.$router.go(0);
      }
      clearTimeout(this.clickTimer);
      this.clickTimer = setTimeout(() => (this.arrowStatus = ""), 100);
    },

    // 操作确认框
    showConfirmHandle(title = "", content = "", callback) {
      this.$confirm(content, title, {
        distinguishCancelAndClose: true,
        confirmButtonText: "确定",
        cancelButtonText: "取消",
      })
        .then(() => {
          callback && callback();
        })
        .catch((e) => "");
    },

    // 展示或隐藏营业日模态框
    showOrHideModelVisible() {
      // this.modelVisible = this.$store.state.cardPageInfo.storeStatusId == 0;
    },

    // 修改密码取消按钮
    cancelUpdatePwdHandle() {
      this.legendOptions.form = {
        old_password: "",
        new_password: "",
        rnew_password: "",
      };
      this.legendOptions.updatePwdModel = false;
    },

    /*
      修改密码
     */

    changePwdHandle(e, text) {
      if (isNaN(e.target._value * 1)) {
        this.$message.warning(text + "必须为数字");
      }
    },

    // 提交修改密码
    async submitUpdatePwdHandle(form = {}) {
      if (!form.old_password) return this.$message.warning("请输入原密码");
      if (!form.new_password) return this.$message.warning("请输入新密码");
      if (form.new_password != form.rnew_password)
        return this.$message.warning("两次输入的新密码不一致！");
      try {
        const res = await api_auth.auth.requestauthchg_pw({
          old_password: md5(form.old_password).toString().toUpperCase(), // string  旧密码(SHA摘要后的)
          new_password: md5(form.new_password).toString().toUpperCase(), // string    新密码(SHA摘要后的)
        });
        if (res.code === 1) {
          this.$message.success("修改密码成功，请重新登录");
          setTimeout(() => {
            this.legendOptions.updatePwdModel = false;
            this.legendOptionHandle("logout");
          }, 1000);
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("修改密码失败", error);
      }
    },
    async logOutHandle() {
      try {
        console.log('log out')
        const res = await api_auth.auth.requestauthlogout();
        if (res.code === 1) {
          // this.$store.commit("updateResResultDataObj", "");
          this.$store.commit("updateUserInfo", "");
          this.$router.replace({
            name: "Thelogin",
            replace: true,
            query: {
              client: "order",
            },
          });
          let version = localStorage.getItem("projectVersion");
          sessionStorage.clear();
          localStorage.clear();
          localStorage.setItem("projectVersion", version);
          this.$websocket.reset();
          this.$message.success("退出成功！");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("logout失败", error);
      }
    },
    // 修改授权密码
    async submitUpdateAuthPwdHandle(authPwdInfo = {}) {
      if (authPwdInfo.show) {
        if (authPwdInfo.authPwd == "" || authPwdInfo.loginPwd == "") {
          return this.$message.warning("登录密码和授权密码不能为空");
        }

        if (authPwdInfo.authPwd != authPwdInfo.repAuthPwd) {
          return this.$message.warning("授权密码与确认授权密码不一致");
        }
        if (authPwdInfo.authPwd == authPwdInfo.loginPwd) {
          return this.$message.warning("授权密码不能与登录密码相同");
        }

        if (isNaN(authPwdInfo.loginPwd * 1)) {
          return this.$message.warning("授权密码必须为数字");
        }
        if (isNaN(authPwdInfo.authPwd * 1)) {
          return this.$message.warning("授权密码必须为数字");
        }
      }

      const params = {
        login_password: authPwdInfo.show
          ? md5(authPwdInfo.loginPwd).toString().toUpperCase()
          : "", // string     //LoginPassword 登录密码(SHA摘要后的)
        auth_password: authPwdInfo.show
          ? md5(authPwdInfo.authPwd).toString().toUpperCase()
          : "", // string     //AuthPassword 授权密码(SHA摘要后的)
      };
      try {
        const res = await api_order.reqUpdateAuthPwd(params);
        if (res.code == 1) {
          this.legendOptions.showAuthPwdModel = false;
          this.$message.success("操作成功！");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("保存授权密码失败", error);
      }
    },

    // 卡台名称放大倍数
    getScaleCardName(cardName) {
      const cardNameLength = this.$overall.character(cardName);
      return Math.min(1, 6 / cardNameLength);
    },
  },

  mounted() {
    // 监听是否有其他人更改订单相关数据
    eventVue.$on("reloadData", (e) => {
      this.getAllData(false);
      if (e && e.func) {
        this.getTabShowCount(e.func);
      }
      e &&
        e.hide &&
        this.showOrHideModelVisible &&
        this.showOrHideModelVisible();
    });
    this.authName =
      this.$store.state.userInfo && this.$store.state.userInfo.name;
    this.showOrHideModelVisible();

    this.getTabShowCount(this.getAllData);
  },
  beforeDestroy() {
    eventVue.$off("reloadData")
  },
  filters: {
    filterTime(timeNumber) {
      if (!timeNumber) return "";
      const hour = timeNumber.slice(9, 11);
      const minute = timeNumber.slice(11, 13);
      return `(${hour}:${minute})`;
    },
  },
  computed: {
    modelVisible() {
      const visible = this.$store.state.cardPageInfo.storeStatusId == 0;
      return visible;
    },
  },
};
