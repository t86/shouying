<template>
  <div class="org">
    <div class="coll m-b-3" layout="row" layout-align="start center">
      <div class="label">门店名称：</div>
      <div class="value">{{detailInfo.org_name}}</div>
    </div>

    <div class="coll m-b-3" layout="row" layout-align="start center">
      <div class="label">营业时间：</div>
      <div class="value">
        <el-select v-model="timeInfo.startValue" class="select" placeholder="请选择营业开始时间">
          <el-option
            v-for="item in timeInfo.options"
            :key="item.value"
            :label="item.label"
            :value="item.value"
          ></el-option>
        </el-select>
        <span>至</span>
        <el-select v-model="timeInfo.endValue" class="select" placeholder="请选择营业结束时间">
          <el-option
            v-for="item in timeInfo.options"
            :key="item.value"
            :label="item.label"
            :value="item.value"
          ></el-option>
        </el-select>
      </div>
    </div>

    <div class="coll m-b-3" layout="row" layout-align="start center">
      <div class="label">联 系 人：</div>
      <div class="value">
        <el-input class="input" v-model="personName" placeholder="请输入联系人"></el-input>
      </div>
    </div>

    <div class="coll m-b-3" layout="row" layout-align="start center">
      <div class="label">门店电话：</div>
      <div class="value">
        <el-input class="input" v-model="phoneNum" placeholder="请输入电话"></el-input>
      </div>
    </div>

    <div class="coll m-b-3" layout="row" layout-align="start center">
      <div class="label">门店地址：</div>
      <div class="value">
        <el-select
          v-model="addressInfo.provinceValue"
          class="select address"
          placeholder="省"
          @change="addressChangeHandle('province')"
        >
          <el-option
            v-for="item in addressInfo.provinceOptions"
            :key="item.id"
            :label="item.n"
            :value="item.id"
          ></el-option>
        </el-select>
        <el-select
          v-model="addressInfo.cityValue"
          class="select address"
          placeholder="市"
          @change="addressChangeHandle('city')"
        >
          <el-option
            v-for="item in addressInfo.cityOptions"
            :key="item.id"
            :label="item.n"
            :value="item.id"
          ></el-option>
        </el-select>
        <el-select v-model="addressInfo.countyValue" class="select address" placeholder="区">
          <el-option
            v-for="item in addressInfo.countyOptions"
            :key="item.id"
            :label="item.n"
            :value="item.id"
          ></el-option>
        </el-select>
      </div>
    </div>
    <!-- 详细地址 -->
    <div class="coll m-b-3" layout="row" layout-align="start center">
      <div class="label"></div>
      <div class="value">
        <el-select
          v-model="addressInfo.detailAddress"
          style="margin-left:80px;"
          class="input"
          filterable
          remote
          reserve-keyword
          placeholder="请输入详细地址"
          :remote-method="searchAddressHandle"
          @change="changeAddressHandle"
        >
          <el-option
            v-for="(item, index) in addressInfo.addressOptions"
            :key="index"
            :label="item.name"
            :value="item.name"
          ></el-option>
        </el-select>
      </div>
    </div>

    <el-button class="button" type="primary" @click.stop="submitHandle">保存</el-button>
  </div>
</template>
<script>
export default {
  data() {
    return {
      detailInfo: {}, //内容
      timeInfo: {
        startValue: "",
        endValue: "",
        options: []
      },
      personName: "",
      phoneNum: "",
      addressInfo: {
        detailAddress: "",
        provinceValue: "",
        provinceOptions: [],
        cityValue: "",
        cityOptions: [],
        countyValue: "",
        countyOptions: [],
        addressOptions: [], // 百度地图检索到的详细地址options
        addressPosition: {} // 详细地址经纬度
      }
    };
  },
  methods: {
    // 请求页面数据
    async getPageData() {
      try {
        const res = await this.$api.BMS.Org.reqGetDetailInfo();
        if (res.code === 1) {
          this.detailInfo = res.data;
          this.timeInfo.startValue = res.data.start_biz_time;
          this.timeInfo.endValue = res.data.end_biz_time;
          this.personName = res.data.contact_name;
          this.phoneNum = res.data.contact_phone;
          this.addressInfo.detailAddress = res.data.addr_dtl;
          this.addressInfo.provinceValue = res.data.addr_province_id || "";
          this.addressInfo.cityValue = res.data.addr_city_id || "";
          this.addressInfo.countyValue = res.data.addr_district_id || "";
          this.addressInfo.addressPosition = {
            lat: res.data.lat,
            lng: res.data.lng
          };
          if (this.addressInfo.provinceValue) {
            this.addressInfo.cityOptions = this.addressInfo.provinceOptions.find(
              item => item.id == this.addressInfo.provinceValue
            ).cs;
          }
          if (this.addressInfo.cityValue && this.addressInfo.countyValue) {
            this.reqGetCountyList(this.addressInfo.cityValue);
          }
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("门店信息获取失败", error);
      }
    },

    getOptions() {
      const options = [];
      for (let i = 0; i < 24; i++) {
        const hour =
          i < 12 ? 12 + i + "00" : (i - 12).toString().padStart(2, 0) + "00";
        const label =
          i < 12
            ? 12 + i + ":00"
            : "次日" + (i - 12).toString().padStart(2, 0) + ":00";

        options.push({
          value: hour,
          label
        });
      }
      this.timeInfo.options = options;
    },

    // 获取省市options
    async reqGetCityList(callback) {
      try {
        const res = await this.$api.BMS.Org.reqGetCityList();
        if (res.code === 1) {
          this.addressInfo.provinceOptions = res.data;
          callback && callback();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取省市数据失败", error);
      }
    },

    // 获取区options
    async reqGetCountyList(cityId) {
      const params = {
        city_id: cityId * 1 //    int  市Id
      };
      try {
        const res = await this.$api.BMS.Org.reqGetCountyList(params);
        res.code === 1
          ? (this.addressInfo.countyOptions = res.data)
          : this.$message.warning(res.msg);
      } catch (error) {
        console.log("获取区options失败", error);
      }
    },

    // 省市select改变监听
    addressChangeHandle(type) {
      switch (type) {
        case "province":
          this.addressInfo.cityValue = this.addressInfo.countyValue = "";
          this.addressInfo.cityOptions = this.addressInfo.provinceOptions.find(
            item => item.id == this.addressInfo.provinceValue
          ).cs;
          this.addressInfo.countyOptions = [];
          break;
        case "city":
          const cityId = this.addressInfo.cityOptions.find(
            item => item.id == this.addressInfo.cityValue
          ).id;
          this.addressInfo.countyValue = "";
          this.addressInfo.countyOptions = [];
          this.reqGetCountyList(cityId);
          break;
      }
    },

    // 提交
    async submitHandle() {
      const params = {
        start_biz_time: this.timeInfo.startValue, // string   营业开始时间
        end_biz_time: this.timeInfo.endValue, // string   营业结束时间
        contact_name: this.personName, // string   联系人名称
        contact_phone: this.phoneNum, // string   联系人电话
        addr_dtl: this.addressInfo.detailAddress, //   string   详细地址
        addr_district_id: this.addressInfo.countyValue, // int    区Id
        lat: this.addressInfo.addressPosition.lat, //   string   纬度
        lng: this.addressInfo.addressPosition.lng //   string    经度
      };
      try {
        const res = await this.$api.BMS.Org.reqSubmitInfo(params);
        res.code === 1
          ? this.$message.success("保存成功！")
          : this.$message.warning(res.msg);
      } catch (error) {
        console.log("提交失败", error);
      }
    },

    // 详细地址
    async searchAddressHandle(query) {
      const params = {
        query,
        region: this.addressInfo.cityOptions.find(
          item => item.id == this.addressInfo.cityValue
        ).n
      };

      try {
        const res = await this.$api.BMS.Org.reqGetAddressList(params);
        if (res.status == 0) {
          this.addressInfo.addressOptions = res.result;
        }
      } catch (error) {
        console.log("百度地址检索失败", error);
      }
    },

    // 获取详细地址所对应的经纬度
    async changeAddressHandle() {
      if(!this.addressInfo.provinceValue) return this.$message.warning('请选择省')
      if(!this.addressInfo.cityValue) return this.$message.warning('请选择市')
      if(!this.addressInfo.countyValue) return this.$message.warning('请选择区')
      const province = this.addressInfo.provinceOptions.find(item => item.id == this.addressInfo.provinceValue).n
      const city = this.addressInfo.cityOptions.find(item => item.id == this.addressInfo.cityValue).n
      const county = this.addressInfo.countyOptions.find(item => item.id == this.addressInfo.countyValue).n
      const address = province + city + county + this.addressInfo.detailAddress
      const params = {
        address   // string   地址
      }

      try {
        const res = await this.$api.BMS.Org.reqGetLatAndLng(params)
        if(res.status==0){
          this.addressInfo.addressPosition = {
            lat: res.result.location.lat.toString(),
            lng: res.result.location.lng.toString()
          }
        }else{
          this.$message.warning('经纬度获取失败')
        }
      } catch (error) {
        console.log('经纬度获取失败',error)
      }
    }
  },
  mounted() {
    this.getOptions();
    this.reqGetCityList(this.getPageData);
  }
};
</script>
<style scoped lang="less">
.org {
  padding: 20px 30px;
  max-height: calc(100vh - 100px);
  overflow: auto;
  box-sizing: border-box;
  .select {
    width: 196px;
  }

  .address {
    width: 136px;
  }

  .input {
    width: 424px;
    color: #40404e;
  }

  .textarea,
  textarea {
    margin-top: 6px;
    width: 426px;
    background-color: #1a1a20 !important;
    color: #40404e !important;
  }

  .button {
    margin-left: 400px;
    margin-top: 40px;
  }
}
</style>
