<template>
  <div>
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      size="60%"
      append-to-body
    >
      <div class="session p-3 fs14">
        <!-- 头部筛选项 -->
        <div class="select-top" layout="col" style="width: 100%;">
          <div class="item p-2" layout="row" layout-align="start center">
            <div class="label">商品分类：</div>
            <div class="value" style="margin: 0 10px">
              <el-cascader
                clearable
                size="small"
                :options="cateOptions"
                v-model="cateVal"
              ></el-cascader>
            </div>
            <div class="m-l-2 m-r-2" style="flex:1;" >
              <el-input v-model="name" placeholder="输入商品名称或拼音字母" size="small"></el-input>
            </div>
            <el-button type="primary" size="small" @click="getTableData(2)">查询</el-button>
            <el-button type="info" size="small" @click="resetHandle">重置</el-button>
          </div>
        </div>
      </div>
      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button size="small" type="info" @click.stop="closeDrawerHandle">取消</el-button>
        <el-button type="primary" size="small" @click="submitHandle">确定</el-button>
      </div>

      <div class="table-content m-l-2">
        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="space-between center">
              <div class="th">
                <el-checkbox
                  v-model="checked"
                  :indeterminate="indeterminate"
                  @change="changeCheckboxHandle('all')"
                >序号</el-checkbox>
              </div>
              <div class="th">商品名称</div>
              <div class="th">所属类别</div>
              <div class="th">商品分类</div>
              <div class="th">商品类型</div>
              <div class="th">营业类型</div>
            </div>
          </div>
          <div class="tbody">
            <div class="tr" layout="row" layout-align="space-between center" v-for="(item, index) in tableData" :key="item.id">
              <div class="td">
                <el-checkbox 
                :checked="item.checked"
                :disabled="item.disabled"
                v-model="item.checked" 
                @change="changeCheckboxHandle('item')">{{index+1}}</el-checkbox>
              </div>
              <div class="td">{{item.n}}</div>
              <div class="td">{{item.jc || '——'}}</div>
              <div class="td">{{ item.on }} > {{ item.tn }}</div>
              <div class="td">{{ item.t }}</div>
              <div class="td">{{item.b}}</div>
            </div>
            <div class="no-data" v-if="tableData.length==0">
              <img :src="require('@/assets/img/wu.png')" alt />
              <p>暂无数据</p>
            </div>
          </div>
        </div>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import { TimeSelect } from 'element-ui';

export default {
  data() {
    return {
      checked: false,
      indeterminate: false,
      show: false,
      // 筛选条件
      name: "",
      cateVal: [0,0],
      cateOptions: [],
      tableData : [],
      selectedPrdIds: [],
    };
  },
  methods: {
    async getTableData(init = 1) {
      try {
        const params = {
          init: init,
          one_cate_id: this.cateVal[0],
          two_cate_id: this.cateVal[1],
          name: this.name
        }
        const res = await this.$api.BMS.statiscalConfig.reqGetRptJkCatePrdItems(params)
        if(res.code == 1) {
          if(init == 1) {
            const cateOptions = res.data.cates || [];
            cateOptions.forEach(el => {
              el.value = el.id;
              el.label = el.n;
              if (el.ss) {
                el.ss.forEach(ele => {
                  ele.value = ele.id;
                  ele.label = ele.n;
                });
                el.children = el.ss;
              }
            });

            this.cateOptions = cateOptions;   
          }
          this.tableData = (res.data.prds || []).map((item) => {
            item.on = this.cateOptions.find(
              (i) => i.value == item.oi
            ).n;
            item.tn = this.cateOptions
              .find((i) => i.value == item.oi)
              .children.find((i) => i.value == item.ti).n;
            item.disabled = item.ji != 0;
            item.checked = item.ji != 0;
            return {
              ...item
            };
          });
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("读取统计分类列表失败", error);
      }
    },
    resetHandle(){
      this.getTableData(1)
    },
    changeCheckboxHandle(type){
      switch(type) {
        case "all":
          this.tableData.forEach(el => {
            el.checked = this.checked;
          });
          this.indeterminate = false;
          break;
        case "item":
          this.checked = this.tableData.every(item => item.checked);
          this.indeterminate =
            !this.checked && this.tableData.some(item => item.checked);
          break;
      }
    },
    async submitHandle() {
      const prds = this.tableData.filter(item => item.checked && !item.disabled)

      if (prds.length <= 0)
        return this.$message.warning("请至少选择一个添加的商品");
        prds.forEach(item => item.disabled = !item.disabled)
      this.closeDrawerHandle(prds);
    },
    // 关闭drawer
    closeDrawerHandle(items = null) {
      this.cateVal = [0,0]
      this.name = ""
      this.$emit("showOrHideDrawerHandle", items);
    }
  },
  props: {
    showDrawer: {
      default: false
    },
    item: {
      default: {}
    }
  },
  computed: {
    title() {
      return "选择商品" 
    },

  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        this.getTableData(1)
      }
    }
  }
};
</script>

<style scoped lang="less">
@import '../../../../../style/common/elementDrawerWine.less';
@import '../../../../../style/common/elementDrawerHeaderAndSession.less';
@import '../../../../../style/common/elementFormBtnWine.less';
@import '../../../../../style/erp/form.less';
@import '../../../../../style/erp/table.less';
</style>

<style scoped lang="less">

.select-top{
  flex-wrap: wrap;

    .item {
      margin: 4px 20px 4px 0;
    }
}

.table-content{
  height: calc(100vh - 200px);
  overflow-y: auto;
  .th,.td{
    &:nth-child(1),
    &:nth-child(4),
    &:nth-child(5),
    &:nth-child(6) {
      width: 15%;
    }

    &:nth-child(2),
    &:nth-child(3) {
      width: 20%;
    }
  }
}

/deep/.el-input__inner{
  background-color: transparent!important;
  color: #40404e!important;
}

// 分类选择框icon
/deep/.el-cascader .el-input .el-icon-arrow-down{
  transform-origin: center 20px;
}

.reqfieldsd {
  font-size: 16px;
  padding-right: 4px;
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.el-icon-arrow-right:before {
  color: #606266;
}
</style>