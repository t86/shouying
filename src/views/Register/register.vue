<template>
  <div class="register" layout="row" layout-align="center center">
    <div class="contain" layout="row" layout-align="center center">
      <img :src="require('@/assets/register-login/denglu_bg.png')" alt />
      <div
        class="register-contain"
        :style="{
          transform: 'translate(-50%, -50%) scale(' + this.scale + ')',
        }"
      >
        <div class="top">检测到当前设备未授权，请先授权</div>
        <div class="center" layout="row" layout-align="start center">
          <img :src="require('@/assets/register-login/code-icon.png')" alt />
          <input type="text" v-model="authCode" placeholder="请输入快捷码" />
        </div>

        <div class="keyboard m-t-10">
          <registerKeyBoard @changeNum="changeNumHandle" />
        </div>

        <div class="btn" @click="submitHandle">提交</div>

        <div class="tips" layout="row" layout-align="center center">
          <div
            class="close"
            layout="row"
            layout-align="start center"
            @click="exitHandle"
          >
            <img :src="require('@/assets/register-login/close_sys.png')" alt />
            <span>关闭系统</span>
          </div>

          <div
            class="position"
            layout="row"
            layout-align="start center"
            @click="changePosition"
            v-if="isAndroidTerminal"
          >
            <img :src="require('@/assets/register-login/qiehuan.png')" alt />
            <span>切换屏幕</span>
          </div>
        </div>
        <div
          class="effect"
          v-if="showEffectArea"
          @click="showEffectHandle"
        ></div>
        <div
          v-if="projectName == 'dev' || projectName == '105'"
          @click="showEffect = true"
        >
          click me
        </div>
      </div>
    </div>

    <!-- 系统选择模态框 -->
    <el-dialog
      title="请选择当前需要登录的系统"
      :visible.sync="showEffect"
      :show-close="false"
      :close-on-click-modal="false"
      :close-on-press-escape="false"
    >
      <ul class="effect">
        <li v-for="(item, i) in effectList" :key="i">
          <el-radio
            v-model="effectRadio"
            :label="i"
            :disabled="item.disabled"
            >{{ item.name }}</el-radio
          >
        </li>
      </ul>
      <div class="login-choose-btn">
        <button class="cancel" @click="showEffect = false">取消</button>
        <button class="ok" @click="submitChooseEffectHandle">确定</button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import api_auth from "@/api/UtilAuth";
import { projectName } from "@/utils/config/projectConfig.js";
import registerKeyBoard from "./registerKeyBoard.vue";
const formHeight = 654; // 注册框的高度
export default {
  data() {
    return {
      projectName,
      authCode: "",
      showEffect: false,
      effectRadio: 0,
      effectList: [
        {
          name: "门店后台",
          client: "org_mgr",
          code: "fiwojcowjvbuiwhfv8172jmv",
          disabled: false,
        },
        {
          name: "预定系统",
          client: "book",
          code: "iwdvowefdwjvhvoepqjdjq221",
          disabled: false,
        },
        {
          name: "点单系统",
          client: "order",
          code: "sfjofdjvcow3dfolwnmvowejw",
          disabled: false,
        },
        {
          name: "收银系统",
          client: "money",
          code: "sp2pvoijgole4mrfjp3240490",
          disabled: false,
        },
        {
          name: "会员系统",
          client: "vip",
          code: "io3i40329uv9f8jvej04rjfg",
          disabled: false,
        },
        {
          name: "物料erp仓库管理员",
          client: "erp",
          code: "2oiej3ojc099u02j3rnv984",
          disabled: false,
        },
        {
          name: "物料erp管理员",
          client: "erpAdmin",
          code: "jvioauhqonvoqj490vjjoah",
          disabled: false,
        },
        {
          name: "存酒-仓库",
          client: "wine",
          code: "iwucvjiwnvio24qyxtaocx0",
          disabled: false,
        },
        {
          name: "叫号大屏",
          client: "queue",
          code: "dfdfjliwijfojoenmfcvnei",
          disabled: false,
        },
      ],
      timer: null,
      count: 0,
      scale: 1, // 输入框放大倍数
    };
  },
  methods: {
    // 防止页面分辨率太小，导致输入框显示在页面可视区域以外
    getPageHeight() {
      const pageHeight = document.body.offsetHeight;
      if (pageHeight - formHeight < 60 && pageHeight - formHeight > 0) {
        this.scale = formHeight / pageHeight - 0.1;
      } else {
        this.scale = 0.8
      }
    },
    changePosition() {
      if (window.atool && "changePosition" in window.atool) {
        atool.changePosition();
      } else {
        this.$message.warning("当前版本还不支持, 请联系系统运维人员升级版本");
      }
    },
    exitHandle() {
      try {
        atool.exit();
      } catch (error) {
        this.$message.warning("当前环境不支持此功能");
      }
    },

    showEffectHandle() {
      if (this.timer) clearTimeout(this.timer);
      this.count++;
      if (this.count >= 6) this.showEffect = true;
      this.timer = setTimeout(() => {
        this.count = 0;
      }, 500);
    },

    // 选择系统
    submitChooseEffectHandle() {
      const chooseEffectInfo = this.effectList[this.effectRadio];
      this.$router.replace("/Thelogin?code=" + chooseEffectInfo.code);
    },

    changeNumHandle(id) {
      if (id == 10) {
        // 清空
        this.authCode = "";
      } else if (id == 12) {
        // 回退
        const authCode = this.authCode.split("");
        authCode.splice(this.authCode.length - 1, 1);
        this.authCode = authCode.join("");
      } else {
        this.authCode = [...this.authCode.split(""), id].join("");
      }
    },

    // 注册设备
    async submitHandle() {
      if (!this.authCode) return this.$message.warning("请输入授权码");
      let machine_code = "";
      try {
        machine_code = atool.getMachineCode();
      } catch (error) {}
      if (machine_code == "")
        return this.$message.warning("当前设备不支持授权");
      const params = {
        auth_code: this.authCode, //  string     //AuthCode 注册码
        machine_code, // string     //MachineCode 机器码
        remark: "", //     string     //Remark 备注
      };
      try {
        const res = await api_auth.auth.reqRegisterTerminal(params);
        if (res.code == 1) {
          atool.setAuthMode(res.data.auth_mode);
          this.$message.success("注册成功");
          this.$router.replace("/Thelogin");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("注册失败", error);
      }
    },
  },
  mounted() {
    this.getPageHeight();
    const that = this;
    function qr_scan_callback() {
      try {
        that.authCode = atool.getQrCode();
      } catch (error) {
        console.log("qrCode信息获取失败：", error);
        that.$message.warning("qrCode信息获取失败：" + error);
      }
    }

    window.qr_scan_callback = qr_scan_callback;
  },
  computed: {
    isAndroidTerminal() {
      let termType = "";
      try {
        termType = atool.getTermType();
      } catch (error) {
        console.log("获取终端类型失败", error);
      }
      return termType == "android";
    },
    showEffectArea() {
      let showArea = true;
      try {
        showArea = !atool.getMachineCode();
      } catch (e) {}
      return showArea;
    },
  },

  components: {
    registerKeyBoard,
  },
};
</script>

<style scoped lang="less">
.register {
  width: 100vw;
  height: 100vh;
  background: #080b16;
  position: relative;

  .switch-position {
    margin-right: 16px;
    display: flex;
    justify-content: center;
    align-items: center;
    color: #367bd5;
    width: 100px;
    border: 1px solid #367bd5;
    border-radius: 4px;
    height: 30px;
    cursor: pointer;
    opacity: 0.6;
    img {
      width: 20px;
      height: 20px;
    }
    &:hover {
      color: #fff;
      border-color: #fff;
      opacity: 1;
    }
  }
  .contain {
    width: 100%;
    max-width: 1024px;
    position: relative;
    img {
      width: 100%;
    }

    .register-contain {
      position: absolute;
      top: 50%;
      left: 50%;
      width: 480px;
      height: 654px;
      background: url("../../assets/register-login/denglukuang_zhuce1.png");
      background-size: 100% 100%;
      color: #fff;

      .top {
        margin-left: 6px;
        margin-right: 12px;
        padding: 66px 0 10px;
        border-bottom: 1px solid rgba(50, 185, 255, 0.3);
        box-sizing: border-box;
        font-size: 20px;
        text-align: center;
      }

      .center {
        margin: 0 auto;
        margin-top: 50px;
        width: 300px;
        height: 44px;
        background: rgba(0, 0, 0, 0.2);
        box-shadow: 0px 0px 8px 0px rgba(26, 137, 255, 0.8);
        border-radius: 6px;
        border: 1px solid #32b9ff;
        padding: 0 10px;
        box-sizing: border-box;
        img {
          width: 24px;
        }
        input {
          outline: none;
          border: none;
          background-color: transparent;
          margin-left: 10px;
          width: 240px;
          height: 40px;
          color: #fff;
          font-size: 16px;
        }

        input::placeholder {
          color: rgba(255, 255, 255, 0.5);
        }
      }

      .btn {
        margin: 40px auto 30px;
        width: 300px;
        height: 56px;
        background: linear-gradient(180deg, #1ed4da 0%, #1edaad 100%);
        border-radius: 31px;
        font-size: 20px;
        color: #08080a;
        line-height: 56px;
        text-align: center;
        cursor: pointer;
      }

      .tips {
        font-size: 14px;
        font-weight: 400;
        color: #1edaad;
        img {
          width: 14px;
          margin-right: 6px;
        }
        .close {
          color: rgba(255, 255, 255, 0.4);
          cursor: pointer;
          margin-right: 20px;
        }
        .position {
          color: rgba(255, 255, 255, 0.4);
          cursor: pointer;
          margin-left: 20px;
        }
      }

      .effect {
        width: 16px;
        height: 16px;
        position: absolute;
        bottom: 0;
        left: 0;
      }
    }
  }
}
</style>

<style lang="less" scoped>
// 弹框样式
/deep/.el-dialog {
  background: linear-gradient(180deg, #08080a 0%, #11182d 100%);
  box-shadow: 0px 0px 10px 0px rgba(26, 137, 255, 0.8);
  border: 1px solid #32b9ff;
  border-radius: 8px;
  width: 40%;

  .el-dialog__footer .dialog-footer {
    button {
      color: #fff;
      &:nth-child(1) {
        background: #374368;
      }
      &:nth-child(2) {
        background: linear-gradient(180deg, #4b89ff 0%, #455eff 100%);
      }
    }
  }
}

/deep/.el-dialog__header {
  background-color: transparent !important;
  .el-dialog__title {
    color: #fff;
  }
}

.effect {
  li {
    padding: 8px 20px;
    box-sizing: border-box;
    font-size: 14px;
    color: #fff;
    input {
      margin-right: 20px;
      cursor: pointer;
    }
  }
}

.login-choose-btn {
  text-align: center;
  margin-top: 20px;
  button {
    padding: 6px 14px;
    margin: 0 8px;
    color: #fff;
    border: none;
    border-radius: 8px;
    &.cancel {
      background: rgba(55, 67, 104, 1);
    }
    &.ok {
      background: #09f;
    }
  }
}

/deep/.el-radio__label {
  color: #fff;
}
</style>
