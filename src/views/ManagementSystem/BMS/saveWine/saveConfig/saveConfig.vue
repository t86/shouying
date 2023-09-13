<template>
  <div class="save-config">
    <div class="coll" layout="row" layout-align="start center">
      <div class="label">过期时间：</div>
      <div class="value">
        <el-radio v-model="radioVal" label="1">12:00</el-radio>
        <el-radio v-model="radioVal" label="2">24:00</el-radio>
      </div>
    </div>
    <div class="tips p-l-10">
      <p class="red-color p-l-8">选择12:00： 酒水在到期日次日中午12点过期</p>
      <p class="red-color p-l-8">选择24:00： 酒水在到期日晚上12点过期</p>
    </div>
    <div class="coll" layout="row" layout-align="start center">
      <div class="label">发送短信：</div>
      <div class="value">
        <el-checkbox
          v-model="item.checked"
          v-for="item in checkboxList"
          :key="item.id"
          >{{ item.n }}</el-checkbox
        >
      </div>
    </div>
    <div class="coll" layout="row" layout-align="start center">
      <div class="label">整瓶有效期：</div>
      <div class="value">
        <el-input
          v-model="day1Val"
          class="m-r-2"
          size="small"
          style="width: 180px"
          placeholder="请输入有效期天数"
          @keyup.native="
            (e) => {
              showMessage(e);
              day1Val = inputLimitPositiveNum(e.target.value);
            }
          "
          @blur="
            (e) => {
              day1Val = formatPointNumber(e.target.value);
            }
          "
        ></el-input
        >天
      </div>
    </div>
    <div class="coll" layout="row" layout-align="start center">
      <div class="label">散瓶有效期：</div>
      <div class="value">
        <el-input
          v-model="day2Val"
          class="m-r-2"
          size="small"
          style="width: 180px"
          placeholder="请输入有效期天数"
          @keyup.native="
            (e) => {
              showMessage(e);
              day2Val = inputLimitPositiveNum(e.target.value);
            }
          "
          @on-blur="
            (e) => {
              day2Val = formatPointNumber(e.target.value);
            }
          "
        ></el-input
        >天
      </div>
    </div>
    <div class="coll" layout="row" layout-align="start center">
      <div class="label">超级授权码：</div>
      <div class="value" layout="row" layout-align="start center">
        <span>{{ wineCode }}</span>
        <el-link
          class="m-l-6"
          type="primary"
          :underline="false"
          @click.native="reloadWineCodeHandle"
          >刷新超级授权码</el-link
        >
      </div>
    </div>
    <div class="coll" layout="row" layout-align="start center">
      <div class="label">客人手机号存酒需要验证码：</div>
      <div class="value" layout="row" layout-align="start center">
        <el-switch v-model="needPhoneValidate" active-color="#2170ff">
        </el-switch>
      </div>
    </div>
    <div class="coll" layout="row" layout-align="start center">
      <div class="label">存酒仓库修改存取酒需要授权：</div>
      <div class="value" layout="row" layout-align="start center">
        <el-switch v-model="needAuthValidate" active-color="#2170ff">
        </el-switch>
      </div>
    </div>
    <div class="coll" layout="row" layout-align="start center">
      <div class="label">存酒小票打印功能：</div>
      <div class="value" layout="row" layout-align="start center">
        <el-switch v-model="enableStorePrt" active-color="#2170ff"> </el-switch>
      </div>
    </div>
    <div
      class="coll"
      layout="row"
      layout-align="start center"
      v-if="enableStorePrt"
    >
      <div class="label"></div>
      <div
        class="value"
        layout="row"
        style="margin-top: -15px"
        layout-align="start center"
      >
        <div>开关开启则需要配置存酒小票打印类型</div>
      </div>
    </div>

    <div
      class="coll"
      layout="row"
      layout-align="start center"
      v-if="enableStorePrt"
    >
      <div class="label"></div>
      <div class="value" layout="row" layout-align="start center">
        <el-radio v-model="storePrtType" label="1">普通打印</el-radio>
        <el-radio v-model="storePrtType" label="2">标签打印</el-radio>
      </div>
    </div>

    <div
      class="coll"
      layout="row"
      layout-align="start center"
      v-if="enableStorePrt && storePrtType == '2'"
    >
      <div class="label">存酒小票标签打印机：</div>
      <div class="value" layout="row" layout-align="start center">
        <el-input
          v-model="labelStorePrtIp"
          class="m-r-2"
          size="small"
          style="width: 180px"
          @input="validateIP"
        ></el-input>
      </div>
    </div>
    <div
      class="coll"
      layout="row"
      layout-align="start center"
      v-if="enableStorePrt && storePrtType == '2'"
    >
      <div class="label"></div>
      <div
        class="value"
        layout="row"
        style="margin-top: -15px"
        layout-align="start center"
      >
        <div>IP地址格式为：a.b.c.d；其中a,b,c,d均为0-255的数字</div>
      </div>
    </div>

    <div class="modal" v-if="showModal">
      <div class="modal-content">
        <div class="title red">免责声明</div>
        <div class="content">
          <div v-if="status == 1">
            <h3>
              关闭开关后，可能会出现以下几种问题，请确认是否关闭？如因关闭开关造成损失，由门店自行承担！
            </h3>
            <p>1、客人输入不正确的手机号，导致找不到自己的存酒或接收不到短信</p>
            <p>2、客人输成别人的手机号，导致酒水寄存到别人名下</p>
          </div>
          <div v-if="status == 2">
            <h3>
              关闭开关后，可能会出现以下几种问题，请确认是否关闭？如因关闭开关造成损失，由门店自行承担！
            </h3>
            <p>
              1、仓库人员自行修改存取酒信息，服务员不知情，导致客户真实存取酒和系统中不同，可能会引起纠纷
            </p>
          </div>
        </div>

        <div class="btn m-t-6" layout="row" layout-align="center center">
          <el-button type="info" size="small" @click="cancelHandle"
            >取消</el-button
          >
          <el-button type="primary" size="small" @click="modelSureHandle"
            >确认</el-button
          >
        </div>
      </div>
    </div>

    <el-button
      type="primary"
      size="small"
      style="margin: 100px 0 0 200px"
      @click.native="saveHandle"
      >保存</el-button
    >
  </div>
</template>

<script>
import { inputLimitPositiveNum, formatPointNumber } from "@/utils/formatNumber";
export default {
  data() {
    return {
      inputLimitPositiveNum,
      formatPointNumber,
      hadLoaded: false, // 页面数据是否加载完成
      radioVal: "1",
      checkboxList: [],
      day1Val: "",
      day2Val: "",
      wineCode: "", // 超级授权码
      needPhoneValidate: true, // 取酒是否需要验证码
      needAuthValidate: true, // 是否需要取酒授权
      enableStorePrt: true,
      storePrtType: "1",
      labelStorePrtIp: "",

      showModal: false, // 是否显示模态框
      status: 1, // 1 修改是否发送验证码  2 修改是否需要授权
    };
  },
  methods: {
    showMessage(e) {
      let value = e.target.value;
      if (value && value.indexOf(".") > -1) {
        this.$message.warning("请输入正整数");
      }
    },
    async getData() {
      try {
        const res = await this.$api.BMS.saveWine.reqGetWineConfig();
        if (res.code == 1) {
          this.checkboxList = (res.data.wine_sms_list || []).map((item) => ({
            ...item,
            checked: item.s == 1,
          }));
          this.radioVal = res.data.end_time_flag.toString();
          this.day1Val = res.data.full_expired_day;
          this.day2Val = res.data.loose_expired_day;
          this.wineCode = res.data.super_auth_code || "";
          this.needPhoneValidate = res.data.cust_in_need_sms == 1;
          this.needAuthValidate = res.data.need_waiter_auth == 1;
          this.enableStorePrt = res.data.enable_store_prt == 1;
          this.storePrtType = res.data.store_prt_type + "";
          this.labelStorePrtIp = res.data.label_store_prt_ip;
          this.setTimeout(() => {
            this.hadLoaded = true;
          }, 1000);
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("读取存酒系统设置数据获取失败", error);
      }
    },

    async saveHandle() {
      if (
        this.enableStorePrt &&
        this.storePrtType != "1" &&
        this.storePrtType != "2"
      ) {
        this.$message.warning("请选择存酒小票打印类型");
        return;
      }
      if (
        this.enableStorePrt &&
        this.storePrtType == "2" &&
        !this.isValidIP(this.labelStorePrtIp)
      ) {
        this.$message.warning("请输入有效的ip地址");
        return;
      }
      const params = {
        end_time_flag: this.radioVal * 1, // int    过期时间 1 中午12点过期, 2 晚上24点过期
        full_expired_day: this.day1Val * 1, // int     整瓶过期天数
        loose_expired_day: this.day2Val * 1, // int     散瓶过期天数
        super_auth_code: this.wineCode, // string   超级授权码,7位数字,授权各类存取酒操作
        cust_in_need_sms: this.needPhoneValidate ? 1 : 2, // int    客户手机号存酒,是否需要手机验证码 1 需要 2 不需要 (如果选择不需要,需要免责条款)
        need_waiter_auth: this.needAuthValidate ? 1 : 2, // int    服务员存/取酒,参考修改,是否要服务员授权 1 需要 2 不需要(如果选择不需要,需要免责条款)
        enable_store_prt: this.enableStorePrt ? 1 : 2, // 存酒小票打印功能
        store_prt_type: this.enableStorePrt
          ? this.storePrtType == "1"
            ? 1
            : 2
          : 0, // 存酒小票打印机类型 1 普通打印机 2 标签打印机
        label_store_prt_ip: this.labelStorePrtIp,
        wine_sms_list: this.checkboxList
          .filter((item) => item.checked)
          .map((item) => item.id), // []int64    选中的短信项Id列表
      };
      try {
        const res = await this.$api.BMS.saveWine.reqUpdateWineConfig(params);
        if (res.code == 1) {
          this.$message.success("保存成功");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("保存存酒系统设置数据失败", error);
      }
    },

    async reloadWineCodeHandle() {
      try {
        const res = await this.$api.BMS.saveWine.reqReloadCode();
        if (res.code == 1) {
          this.wineCode = res.data.super_auth_code;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("刷新超级授权码失败", error);
      }
    },

    modelSureHandle() {
      if (this.status == 1) this.needPhoneValidate = false;
      if (this.status == 2) this.needAuthValidate = false;
      this.showModal = false;
    },

    cancelHandle() {
      if (this.status == 1) this.needPhoneValidate = true;
      if (this.status == 2) this.needAuthValidate = true;
      this.showModal = false;
    },

    validateIP(ip) {
      // 验证 IP 前缀的正则
      const prefixRegex =
        /^((([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){0,3})([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])?$/;

      function isValidIPPrefix(value) {
        return prefixRegex.test(value);
      }

      if (!isValidIPPrefix(ip)) {
        console.log("invalid", ip);
        this.$message.error("请输入有效的 IP 前缀");
      } else {
        console.log("valid", ip);
      }
    },
    isValidIP(str) {
      const regex =
        /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/;

      return regex.test(str);
    },
  },
  created() {
    this.getData();
  },
  watch: {
    needPhoneValidate(newVal) {
      if (newVal == false && this.hadLoaded) {
        this.status = 1;
        this.showModal = true;
      }
    },
    needAuthValidate(newVal) {
      if (newVal == false && this.hadLoaded) {
        this.status = 2;
        this.showModal = true;
      }
    },
  },
};
</script>

<style scoped lang="less">
.save-config {
  padding: 20px;
  .coll {
    margin-top: 30px;
    font-size: 14px;
    .label {
      width: 260px;
      text-align: right;
    }
    .value {
      padding-left: 6px;
      box-sizing: border-box;
      width: calc(100% - 120px);
    }
  }

  .tips {
    margin-top: 10px;
    margin-left: 110px;
    p {
      font-size: 14px;
      line-height: 20px;
      margin-left: 40px;
    }
  }

  .modal {
    position: fixed;
    width: 100vw;
    height: 100vh;
    background-color: rgba(0, 0, 0, 0.5);
    left: 0;
    top: 0;
    z-index: 1;
    .modal-content {
      position: absolute;
      left: 50%;
      top: 45%;
      transform: translate(-50%, -50%);
      padding: 20px 30px;
      width: 500px;
      background-color: #f9f9f9;
      border-radius: 10px;
      .title {
        font-size: 20px;
        font-weight: 600;
      }

      .red {
        color: #f56c6c;
      }

      .content {
        h3 {
          font-size: 16px;
          margin: 20px 0;
          line-height: 26px;
        }
        p {
          font-size: 16px;
          line-height: 30px;
        }
      }
    }
  }
}
</style>
