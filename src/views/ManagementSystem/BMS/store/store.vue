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
      <div class="label">协助地图定位用:</div>
      <div class="value">
        <el-select
          v-model="addressInfo.detailAddress"
          class="input"
          filterable
          remote
          auto-create
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
    <div class="coll m-b-3" layout="row" layout-align="start center">
        <div class="label">客户端展示用:</div>
        <el-input
          v-model="addressInfo.customAddress"
          style="width: 424px;"
          placeholder="或输入自定义地址"
          @input="handleCustomAddressInput"
        ></el-input>
    </div>

    <div style="color:red;font-size: 24px; margin: 10px;">鼠标点击可调整门店位置</div>
    <el-card>
      <div id="map" style="height: 400px;"></div>
    </el-card>

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
        addressOptions: [], // 地图检索到的详细地址options
        addressPosition: {} // 详细地址经纬度
      },
      map: null,
    };
  },
  methods: {
    // BD-09坐标转WGS84坐标（百度地图坐标系转国际标准坐标系）
    // 用于解决在中国大陆地区的坐标偏移问题
    bd09ToWgs84(bdLng, bdLat) {
      const x_PI = (3.14159265358979324 * 3000.0) / 180.0;
      const PI = 3.1415926535897932384626;
      const a = 6378245.0;
      const ee = 0.00669342162296594323;
      
      let x = bdLng - 0.0065;
      let y = bdLat - 0.006;
      let z = Math.sqrt(x * x + y * y) - 0.00002 * Math.sin(y * x_PI);
      let theta = Math.atan2(y, x) - 0.000003 * Math.cos(x * x_PI);
      let wgsLng = z * Math.cos(theta);
      let wgsLat = z * Math.sin(theta);
      
      // GCJ-02转WGS84
      let dLat = this.transformLat(wgsLng - 105.0, wgsLat - 35.0);
      let dLng = this.transformLng(wgsLng - 105.0, wgsLat - 35.0);
      let radLat = (wgsLat / 180.0) * PI;
      let magic = Math.sin(radLat);
      magic = 1 - ee * magic * magic;
      let sqrtMagic = Math.sqrt(magic);
      dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * PI);
      dLng = (dLng * 180.0) / (a / sqrtMagic * Math.cos(radLat) * PI);
      
      return {
        lng: wgsLng - dLng,
        lat: wgsLat - dLat
      };
    },
    
    // WGS84坐标转BD-09坐标（国际标准坐标系转百度地图坐标系）
    wgs84ToBd09(wgsLng, wgsLat) {
      const x_PI = (3.14159265358979324 * 3000.0) / 180.0;
      const PI = 3.1415926535897932384626;
      const a = 6378245.0;
      const ee = 0.00669342162296594323;
      
      // WGS84转GCJ-02
      let dLat = this.transformLat(wgsLng - 105.0, wgsLat - 35.0);
      let dLng = this.transformLng(wgsLng - 105.0, wgsLat - 35.0);
      let radLat = (wgsLat / 180.0) * PI;
      let magic = Math.sin(radLat);
      magic = 1 - ee * magic * magic;
      let sqrtMagic = Math.sqrt(magic);
      dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * PI);
      dLng = (dLng * 180.0) / (a / sqrtMagic * Math.cos(radLat) * PI);
      
      let gcjLng = wgsLng + dLng;
      let gcjLat = wgsLat + dLat;
      
      // GCJ-02转BD-09
      let z = Math.sqrt(gcjLng * gcjLng + gcjLat * gcjLat) + 0.00002 * Math.sin(gcjLat * x_PI);
      let theta = Math.atan2(gcjLat, gcjLng) + 0.000003 * Math.cos(gcjLng * x_PI);
      let bdLng = z * Math.cos(theta) + 0.0065;
      let bdLat = z * Math.sin(theta) + 0.006;
      
      return {
        lng: bdLng,
        lat: bdLat
      };
    },
    
    // 辅助函数：纬度转换
    transformLat(lng, lat) {
      const PI = 3.1415926535897932384626;
      let ret = -100.0 + 2.0 * lng + 3.0 * lat + 0.2 * lat * lat + 0.1 * lng * lat + 0.2 * Math.sqrt(Math.abs(lng));
      ret += ((20.0 * Math.sin(6.0 * lng * PI) + 20.0 * Math.sin(2.0 * lng * PI)) * 2.0) / 3.0;
      ret += ((20.0 * Math.sin(lat * PI) + 40.0 * Math.sin(lat / 3.0 * PI)) * 2.0) / 3.0;
      ret += ((160.0 * Math.sin(lat / 12.0 * PI) + 320 * Math.sin(lat * PI / 30.0)) * 2.0) / 3.0;
      return ret;
    },
    
    // 辅助函数：经度转换
    transformLng(lng, lat) {
      const PI = 3.1415926535897932384626;
      let ret = 300.0 + lng + 2.0 * lat + 0.1 * lng * lng + 0.1 * lng * lat + 0.1 * Math.sqrt(Math.abs(lng));
      ret += ((20.0 * Math.sin(6.0 * lng * PI) + 20.0 * Math.sin(2.0 * lng * PI)) * 2.0) / 3.0;
      ret += ((20.0 * Math.sin(lng * PI) + 40.0 * Math.sin(lng / 3.0 * PI)) * 2.0) / 3.0;
      ret += ((150.0 * Math.sin(lng / 12.0 * PI) + 300.0 * Math.sin(lng / 30.0 * PI)) * 2.0) / 3.0;
      return ret;
    },
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
          this.addressInfo.customAddress = res.data.addr_dtl_disp;
          this.addressInfo.provinceValue = res.data.addr_province_id || "";
          this.addressInfo.cityValue = res.data.addr_city_id || "";
          this.addressInfo.countyValue = res.data.addr_district_id || "";
          // 后端可能返回BD-09坐标（百度坐标系），需要转换为WGS84（OpenStreetMap使用）
          const bdLat = parseFloat(res.data.lat);
          const bdLng = parseFloat(res.data.lng);
          const wgs84 = this.bd09ToWgs84(bdLng, bdLat);
          
          // 保存原始坐标（后端可能需要BD-09格式）
          this.addressInfo.addressPosition = {
            lat: res.data.lat,
            lng: res.data.lng
          };
          
          if (this.map && this.marker) {
            // Leaflet使用WGS84坐标 [lat, lng] 格式
            this.marker.setLatLng([wgs84.lat, wgs84.lng]);
            this.map.setView([wgs84.lat, wgs84.lng], 18);
          }
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
        addr_dtl_disp: this.addressInfo.customAddress, //   string   详细地址展示
        addr_district_id: this.addressInfo.countyValue, // int    区Id
        lat: this.addressInfo.addressPosition.lat.toString(), //   string   纬度
        lng: this.addressInfo.addressPosition.lng.toString() //   string    经度
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
        console.log("地址检索失败", error);
      }
    },

    handleCustomAddressInput(value){
      console.log('自定义地址', this.addressInfo.customAddress, value)
      this.addressInfo = {...this.addressInfo}
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
          // 后端可能返回BD-09坐标（百度坐标系），需要转换为WGS84（OpenStreetMap使用）
          const bdLat = parseFloat(res.result.location.lat.toString());
          const bdLng = parseFloat(res.result.location.lng.toString());
          const wgs84 = this.bd09ToWgs84(bdLng, bdLat);
          
          // 保存原始坐标（后端可能需要BD-09格式）
          this.addressInfo.addressPosition = {
            lat: res.result.location.lat.toString(),
            lng: res.result.location.lng.toString()
          }
          console.log('设置经纬度', { bd09: { lat: bdLat, lng: bdLng }, wgs84 })
          if (this.map && this.marker) {
            // Leaflet使用WGS84坐标 [lat, lng] 格式
            this.marker.setLatLng([wgs84.lat, wgs84.lng]);
            this.map.setView([wgs84.lat, wgs84.lng], 18);
          }
          
        }else{
          this.$message.warning('经纬度获取失败')
        }
      } catch (error) {
        console.log('经纬度获取失败',error)
      }
    },
    loadLeafletScript() {
      return new Promise((resolve, reject) => {
        // 检查是否已经加载
        if (window.L) {
          resolve();
          return;
        }
        
        // 加载 Leaflet CSS
        const link = document.createElement('link');
        link.rel = 'stylesheet';
        link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
        link.integrity = 'sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=';
        link.crossOrigin = '';
        document.head.appendChild(link);
        
        // 加载 Leaflet JS
        const script = document.createElement('script');
        script.type = 'text/javascript';
        script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
        script.integrity = 'sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=';
        script.crossOrigin = '';
        
        script.onload = () => {
          resolve();
        };
        
        script.onerror = () => {
          reject(new Error('加载Leaflet地图库失败，请检查网络连接'));
        };
        
        document.head.appendChild(script);
      });
    },
    initMap() {
      if (!window.L) {
        console.error('Leaflet地图库未加载');
        return;
      }
      
      // 初始化地图，使用OpenStreetMap作为底图（完全免费）
      this.map = L.map('map', {
        center: [39.90923, 116.397428], // 默认北京中心点 [lat, lng]
        zoom: 13
      });
      
      // 添加OpenStreetMap图层
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors',
        maxZoom: 19
      }).addTo(this.map);
      
      // 创建标记（可拖拽）
      this.marker = L.marker([0, 0], {
        draggable: true
      }).addTo(this.map);
      
      // 地图点击事件
      this.map.on('click', (e) => {
        const wgsLat = e.latlng.lat;
        const wgsLng = e.latlng.lng;
        
        // OpenStreetMap返回的是WGS84坐标，需要转换为BD-09（如果后端需要）
        const bd09 = this.wgs84ToBd09(wgsLng, wgsLat);
        
        // 保存BD-09坐标（后端可能需要BD-09格式）
        this.addressInfo.addressPosition = {
          lat: bd09.lat.toString(),
          lng: bd09.lng.toString()
        };
        this.marker.setLatLng([wgsLat, wgsLng]);
      });
      
      // 标记拖拽事件
      this.marker.on('dragend', (e) => {
        const wgsLat = e.target.getLatLng().lat;
        const wgsLng = e.target.getLatLng().lng;
        
        // OpenStreetMap返回的是WGS84坐标，需要转换为BD-09（如果后端需要）
        const bd09 = this.wgs84ToBd09(wgsLng, wgsLat);
        
        // 保存BD-09坐标（后端可能需要BD-09格式）
        this.addressInfo.addressPosition = {
          lat: bd09.lat.toString(),
          lng: bd09.lng.toString()
        };
      });
    },
  },
  mounted() {
    this.loadLeafletScript().then(() => {
      this.initMap();
    }).catch((error) => {
      console.error('地图加载失败:', error);
      this.$message.error('地图加载失败，请检查网络连接');
    });
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

.label {
  width: 150px;
  text-align: left;
  color: #40404e;
}
</style>
