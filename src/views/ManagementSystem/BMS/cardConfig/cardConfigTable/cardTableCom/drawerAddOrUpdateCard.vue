<template>
  <div>
    <!-- 新增或修改 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5 fs14">
        <div class="coll m-b-6" layout="row" layout-align="start center">
          <div class="label">
            <span>当前区域：</span>
          </div>
          <div class="value">{{areaName}}</div>
        </div>
        <div class="coll m-b-6" layout="row" layout-align="start center">
          <div class="label">
            <span class="red">*</span>
            <span>卡台名称:</span>
          </div>
          <div class="value">
            <el-input v-model="cardName" size="mini" placeholder="请填写卡台名称" @input="validator('cardName')"></el-input>
          </div>
        </div>
        <div class="coll m-b-6" layout="row" layout-align="start center">
          <div class="label">
            <span class="red">*</span>
            <span>可坐人数:</span>
          </div>
          <div class="value">
            <el-input v-model="personNum" size="mini" placeholder="请填写数字" @input="validator('personNum')"></el-input>
          </div>
        </div>
        <div class="coll m-b-6" layout="row" layout-align="start center">
          <div class="label">
            <span class="red">*</span>
            <span>卡台类型:</span>
          </div>
          <div class="value">
            <el-select v-model="cardType" placeholder="请选择类型" size="mini">
              <el-option label="散台" :value="1"></el-option>
              <el-option label="吧台" :value="2"></el-option>
              <el-option label="卡座" :value="3"></el-option>
              <el-option label="包厢" :value="4"></el-option>
            </el-select>
          </div>
        </div>
        <div class="coll m-b-6" layout="row" layout-align="start center">
          <div class="label">
            <span class="red">*</span>
            <span>业务类型:</span>
          </div>
          <div class="value">
            <el-select v-model="businessType" placeholder="请选择类型" size="mini">
              <el-option label="实体台" :value="1"></el-option>
              <el-option label="虚拟台" :value="2"></el-option>
              <el-option label="关联功能台" :value="3"></el-option>
              <el-option label="功能台" :value="4"></el-option>
            </el-select>
          </div>
        </div>
        
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button v-if="search" type="danger" @click="deleteHandle">删除</el-button>
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      areaId: '',
      cardName: '',
      personNum: '1',
      cardType: '',
      businessType: ''
    };
  },
  methods: {
    async getCardDetail(){
      const params = {
        id: this.currentInfo.id * 1
      }
      try {
        const res = await this.$api.BMS.seat.requestseatget(params)
        if (res.code == 1) {
          this.areaId = res.data.region_id
          this.cardName = res.data.name
          this.personNum = res.data.capacity
          this.cardType = res.data.seat_type * 1
          this.businessType = res.data.biz_type * 1
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取编辑开台信息失败', error);
      }
    },

    async deleteHandle(){
      const params = {
        ids: [this.currentInfo.id]
      }
      try {
        const res = await this.$api.BMS.seat.requestseatdel(params)
        if(res.code == 1) {
          this.onCancelDrawer()
          this.$message.success('删除成功')
          this.$emit("getTableData");
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('删除失败', error);
      }
    },

    async onSubmit() {
      if(!this.validator('cardName')) return
      if(!this.validator('personNum')) return
      if (!this.cardType)
        return this.$message.warning("请选择卡台类型");
      if (!this.businessType)
        return this.$message.warning("请选择业务类型");
      const params = {
        region_id: this.$route.query.menuId * 1,
        seat_name: this.cardName,
        capacity: this.personNum * 1,
        seat_type: this.cardType * 1,
        biz_type: this.businessType * 1,
        ...(this.type == 2 && { id: this.currentInfo.id * 1 }),
        ...(this.type == 2 && { name: this.cardName })
      };
      try {
        const api = this.type == 1 ? "requestseatnew" : "requestseatsave";
        const res = await this.$api.BMS.seat[api](params);
        if (res.code == 1) {
          this.onCancelDrawer();
          this.$emit("getTableData", true);
          this.$message.success("操作成功");
        } else if(res.code == 6) {
          this.$message.warning("创建成功，状态无效，" + res.msg)
          this.onCancelDrawer();
          this.$emit("getTableData", true);
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("新增失败", error);
      }
    },

    // form表单检测
    validator(val){
      switch (val) {
        case "cardName":
          if (this.cardName == '') {
            this.$message.warning('请输入卡台名称')
            return false
          } else if (this.$overall.character(this.cardName) > 16) {
            this.$message.warning('输入文字长度超过8')
            return false
          }
          return true
        case "personNum":
          if (this.personNum == '') {
            this.$message.warning('请输入可坐人数')
            return false
          } else if (this.$overall.character(this.personNum) > 2) {
            this.$message.warning('输入文字长度超过1')
            return false
          }
          return true
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
    },
    search: {
      default: false
    },
    menuList: {
      default: () => ({})
    }
  },
  computed: {
    title() {
      return this.type == 1 ? "新增卡台" : "编辑卡台";
    },

    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      }
    },

    areaName(){
      const areaInfo = this.menuList.find(item => item.id == (this.search ? this.areaId : this.$route.query.menuId))
      return areaInfo && areaInfo.n
    }
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          if(this.type == 1) {
            this.cardName = ''
            this.personNum = '1'
            this.cardType = ''
            this.businessType = ''
          } else {
            this.getCardDetail()
          }
        }
      },
      immediate: true
    },
  }
};
</script>

<style scoped lang="less">
@import "../../../../../../style/common/elementDrawerWine.less";
@import "../../../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../../../style/common/elementFormBtnWine.less";
@import "../../../../../../style/erp/form.less";
</style>