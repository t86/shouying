<template>
  <div>
    <!-- 新增或修改区域 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5 fs14">
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="red">*</span>
            <span>区域名称</span>
          </div>
          <div class="value">
            <el-input
              v-model="areaName"
              size="mini"
              placeholder="请输入区域名称"
              @input="validator"
            ></el-input>
          </div>
        </div>
        <div v-if="type == 2" class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span>必点商品</span>
          </div>
          <div class="value" layout="row" layout-align="start center">
            <div
                v-for="(item, index) in musts" layout="row" layout-align="start center">
              <div
                style="padding:5px;border-radius:2px"
                layout="row"
                layout-align="start center"
                class="m-r-1"
              >
                <span style="color:#40404e">{{item.n}}</span>
                <i class="el-icon-error cursor" @click="deleteMust(item)"></i>
              </div>
            </div>
            <el-button type="primary" size="mini" @click="showDrawer = true">{{musts.length > 0 ? '修改商品' : '添加商品'}}</el-button>
          </div>
        </div>
        <p v-if="type == 2" class="m-t-3 m-l-10 red-color fs12">启用必点商品后，该区域的卡台需要点单该商品后才可下单</p>
        <drawerChoosePrd v-model="showDrawer" :currentInfo="musts" @getChoosePrdHandle="getChoosePrdHandle" />
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import drawerChoosePrd from './drawerChoosePrd.vue'
export default {
  data() {
    return {
      areaName: "",
      
      // choosePrdInfo: {}, // 必点商品
      musts:[],
      showDrawer: false,
    };
  },
  methods: {
    deleteMust(item){
      this.musts = this.musts.filter(i => i.id !== item.id)
    },
    async getAreaInfo(){
      const params = {
        id: this.currentInfo.id * 1
      }
      try {
        const res = await this.$api.BMS.region.requestregionget(params)
        if(res.code == 1) {
          console.log(res);
          this.areaName = res.data.name
          // this.choosePrdInfo = {
          //   n: res.data.must_order_prd_name,
          //   id: res.data.must_order_prd_id
          // }
          let m0 = {
            id: res.data.must_order_prd_id,
            n: res.data.must_order_prd_name
          }
          if(m0.id > 0){
            this.musts.push(m0)
          }
          let m1 = {
            id: res.data.must_order_prd_id2,
            n: res.data.must_order_prd_name2
          }
          if(m1.id > 0){
            this.musts.push(m1)
          }
          let m2 = {
            id: res.data.must_order_prd_id3,
            n: res.data.must_order_prd_name3
          }
          if(m2.id > 0){
            this.musts.push(m2)
          }
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取区域详情失败', error);
      }
    },

    validator() {
      if (this.areaName == "") {
        this.$message.warning("请输入区域名称")
        return false
      } else if (this.$overall.character(this.areaName) > 4) {
        this.$message.warning("输入文字长度超过2")
        return false
      }
      return true
    },

    getChoosePrdHandle(info){
      console.log("getChoosePrdHandle", info)
      // this.choosePrdInfo = {...info}
      // this.musts = new Set([...this.musts, ...info])

      let toInsert = []
      for(let i of info){
        let idx = this.musts.findIndex(item => item.id === i.id)
        if (idx === -1){
          toInsert.push(i)
        }
      }
      if (this.musts.length  + toInsert.length > 3) {
        this.$message.warning("做多支持3个必点商品")
        return
      }
      this.musts = [...this.musts, ...toInsert]
    },

    async onSubmit() {
      if(!this.validator()) return
      const params = {
        name: this.areaName || '',
        ...this.type == 2 && {id : this.currentInfo.id},
        // ...this.type == 2 && {must_order_prd_id : this.choosePrdInfo.id || 0},
      };
      let must_order_prd_id = 0      //MustOrderPrdId 必点商品Id,没有=0
      let must_order_prd_name = ''     //MustOrderPrdName 必点商品名称,没有=空
      let must_order_prd_id2 = 0      //MustOrderPrdId2 必点商品2Id,没有=0
      let must_order_prd_name2 = ''     //MustOrderPrdName2 必点商品2名称,没有=空
      let must_order_prd_id3 = 0      //MustOrderPrdId3 必点商品3Id,没有=0
      let must_order_prd_name3 = ''     //MustOrderPrdName3 必点商品3名称,没有=空
      if (this.type === 2){
        if(this.musts.length === 1){
          must_order_prd_id = this.musts[0].id
          must_order_prd_name = this.musts[0].n
        } else if (this.musts.length === 2){
          let m0 = this.musts[0]
          let m1 = this.musts[1]
          must_order_prd_id = m0.id
          must_order_prd_name = m0.n
          must_order_prd_id2 = m1.id
          must_order_prd_name2 = m1.n
        } else if (this.musts.length === 3){
          let m0 = this.musts[0]
          let m1 = this.musts[1]
          let m2 = this.musts[2]
          must_order_prd_id = m0.id
          must_order_prd_name = m0.n
          must_order_prd_id2 = m1.id
          must_order_prd_name2 = m1.n
          must_order_prd_id3 = m2.id
          must_order_prd_name3 = m2.n
        }
        params.must_order_prd_id = must_order_prd_id      //MustOrderPrdId 必点商品Id,没有=0
        params.must_order_prd_name = must_order_prd_name     //MustOrderPrdName 必点商品名称,没有=空
        params.must_order_prd_id2 = must_order_prd_id2      //MustOrderPrdId2 必点商品2Id,没有=0
        params.must_order_prd_name2 = must_order_prd_name2     //MustOrderPrdName2 必点商品2名称,没有=空
        params.must_order_prd_id3 = must_order_prd_id3      //MustOrderPrdId3 必点商品3Id,没有=0
        params.must_order_prd_name3 = must_order_prd_name3     //MustOrderPrdName3 必点商品3名称,没有=空
      }
      try {
        const api = this.type == 1 ? 'requestregionnew' : 'requestregionsave'
        const res = await this.$api.BMS.region[api](params)
        if(res.code == 1) {
          this.onCancelDrawer()
          this.$emit('getTableData', true)
          this.$emit('getMenuList')
          this.$message.success('操作成功')
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('新增失败', error);
      }
    },

    onCancelDrawer() {
      this.show = false;
    }
  },
  mounted() {},
  props: {
    value: {
      default: false // 是否显示drawer
    },
    type: {
      default: 1
    },
    currentInfo: {
      default: () => ({})
    }
  },
  computed: {
    title() {
      return this.type == 1 ? "新增区域" : "编辑区域";
    },

    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      }
    }
  },
  components: {
    drawerChoosePrd
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          if (this.type == 1) {
            this.areaName = "";
          } else {
            this.musts = []
            this.getAreaInfo()
          }
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../../../style/common/elementDrawerWine.less";
@import "../../../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../../../style/common/elementFormBtnWine.less";
@import "../../../../../../style/erp/form.less";
</style>