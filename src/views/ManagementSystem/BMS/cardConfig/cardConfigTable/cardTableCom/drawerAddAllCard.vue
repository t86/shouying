<template>
  <div>
    <!-- 批量新增 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5 fs14">
        <p class="red-color fs12">说明：如果卡台已存在，批量添加时则会跳过</p>
        <div class="coll m-b-6" layout="row" layout-align="start center">
          <div class="label">
            <span>当前区域：</span>
          </div>
          <div class="value">{{areaName}}</div>
        </div>
        <div class="coll m-b-6" layout="row" layout-align="start center">
          <div class="label">
            <span class="red-color">*</span>
            <span>编号：</span>
          </div>
          <div class="value" layout="row" layout-align="start center">
            <input
              style="width: 100px;height: 30px; padding: 4px 10px;box-sizing:border-box"
              v-model="startNum"
              placeholder="起始编号"
            />
            <div class="m-l-3 m-r-3">至</div>
            <input
              style="width: 100px;height: 30px; padding: 4px 10px;box-sizing:border-box"
              v-model="endNum"
              placeholder="结束编号"
            />
            <el-checkbox style="margin-left: 30px;" v-model="isFilter">删除数字4、7、13</el-checkbox>
          </div>
        </div>
        <div class="coll m-b-6" layout="row" layout-align="start center">
          <div class="label">
            <span class="red-color">*</span>
            <span>编号位数：</span>
          </div>
          <div class="value">
            <input
              style="width: 300px;height: 30px; padding: 4px 10px;box-sizing:border-box"
              v-model="numCount"
              placeholder="请输入编号位数"
            />
          </div>
        </div>
        <div class="coll m-b-6" layout="row" layout-align="start center">
          <div class="label">
            <span>卡台名称前缀：</span>
          </div>
          <div class="value">
            <input
              style="width: 300px;height: 30px; padding: 4px 10px;box-sizing:border-box"
              v-model="prefix"
              placeholder="名称格式“卡台前缀”+“编号”"
            />
          </div>
        </div>
        <div class="coll m-b-6" layout="row" layout-align="start center">
          <div class="label">
            <span>可坐人数：</span>
          </div>
          <div class="value">
            <input
              style="width: 300px;height: 30px; padding: 4px 10px;box-sizing:border-box"
              v-model="personCount"
              placeholder="请输入人数"
            />
          </div>
        </div>
        <div class="coll m-b-6" layout="row" layout-align="start center">
          <div class="label">
            <span class="red-color">*</span>
            <span>卡台类型：</span>
          </div>
          <div class="value">
            <el-select v-model="cardType" placeholder="请选择类型" class="controlling">
              <el-option label="散台" :value="1"></el-option>
              <el-option label="吧台" :value="2"></el-option>
              <el-option label="卡座" :value="3"></el-option>
              <el-option label="包厢" :value="4"></el-option>
            </el-select>
          </div>
        </div>
        <div class="coll m-b-6" layout="row" layout-align="start center">
          <div class="label">
            <span class="red-color">*</span>
            <span>业务类型：</span>
          </div>
          <div class="value">
            <el-select v-model="businessType" placeholder="请选择类型" class="controlling">
              <el-option label="实体台" :value="1"></el-option>
              <el-option label="虚拟台" :value="2"></el-option>
              <el-option label="关联台" :value="3"></el-option>
            </el-select>
          </div>
        </div>
        <div class="coll m-b-6" layout="row" layout-align="start center">
          <div class="label">
            <span>卡台预览：</span>
          </div>
          <div class="value">
            <div v-if="startNum >= 0 && endNum > 0">
              <div v-if="startNum >= 0">{{startCardName}}</div>
              <div>......</div>
              <div v-if="endNum >= 0">{{endCardName}}</div>
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
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
      startNum: '',
      endNum: '',
      isFilter: false, 
      numCount: '1',
      prefix: '',
      personCount: '',
      cardType: '',
      businessType: '',
    };
  },
  methods: {
    async onSubmit(){
      if(
        this.startNum === '' ||
        this.endNum === '' ||
        this.numCount < 0 ||
        this.cardType === '' ||
        this.businessType === ''
      ) return this.$message.warning('必选框不能为空')
      const params = {
        region_id: this.$route.query.menuId * 1,
        begin_num: this.startNum * 1,
        end_num: this.endNum * 1,
        num_length: this.numCount * 1,
        exclude_spec_num: this.isFilter ? 1 : 2, //int   删除特殊数字  1 删除, 2 不删除
        name_prefix: this.prefix,
        capacity: this.personCount * 1, // int  座位数,人数
        seat_type: this.cardType * 1, // int   卡台类型   1 散台   2  吧台  3 卡座 4 包厢
        biz_type: this.businessType * 1, // int   业务类型 1 实体台  2 虚拟台  3 (鸡尾酒)补交台
      }
      try {
        const res = await this.$api.BMS.seat.requestseatbatch_new(params)
        if(res.code == 1) {
          this.$message.success('新增成功')
          this.onCancelDrawer()
          this.$emit('getTableData', true)
        } else if (res.code == 6) {
          this.onCancelDrawer()
          this.$emit('getTableData', true)
          this.$message.warning("创建成功，状态无效，" + res.msg)
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('批量创建卡台失败', error);
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
    menuList: {
      default: () => ({})
    }
  },
  computed: {
    title() {
      return "批量新增";
    },

    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      }
    },

    areaName() {
      const areaInfo = this.menuList.find(
        item => item.id == this.$route.query.menuId * 1
      );
      return areaInfo && areaInfo.n;
    },

    startCardName(){
      let result = ''
      if(this.startNum >= 0 && this.numCount > 0) {
        for (let i = 0; i < 5; i++) {
          result += (this.isFilter && (this.startNum * 1 + i).toString().endsWith('4') || (this.startNum * 1 + i).toString().endsWith('7') || (this.startNum * 1 + i).toString().endsWith('13')) ? '' : (this.prefix ? this.prefix + '-' : '') + (this.startNum * 1 + i).toString().padStart(this.numCount * 1, 0) + '、'
        };
      }
      return result
    },
    endCardName(){
      let result = ''
      if(this.endNum >= 0 && this.numCount > 0) {
        for (let i = 0; i < 5; i++) {
          result += (this.isFilter && (this.endNum * 1 - 4 + i).toString().endsWith('4') || (this.endNum * 1 - 4 + i).toString().endsWith('7') || (this.endNum * 1 - 4 + i).toString().endsWith('13')) ? '' : (this.prefix ? this.prefix + '-' : '') + (this.endNum * 1 - 4 + i).toString().padStart(this.numCount * 1, 0) + (i == 4 ? '' :'、')
        };
      }
      return result
    }
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.startNum =  ''
          this.endNum =  ''
          this.isFilter = false
          this.numCount =  '1'
          this.prefix =  ''
          this.personCount =  ''
          this.cardType =  ''
          this.businessType =  ''
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
@import "../../../../../../style/erp/table.less";
</style>
<style lang="less" scoped>
.table-content {
  .table {
    height: calc(100vh - 250px);
    overflow: auto;
    .th,
    .td {
      &:nth-child(1) {
        width: 40%;
      }
    }
  }
}
</style>