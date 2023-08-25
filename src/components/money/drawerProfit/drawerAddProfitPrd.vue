<template>
  <div>
    <!-- 盘盈盘亏 -->
    <el-drawer
      title="添加盘盈盘亏单"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="90%"
    >
      <div class="profit-prd">
        <div class="profit-top">
          <div class="profit-top-open m-t-3" layout="row" layout-align="start center">
            <span><span style="color:red">*</span> 出品库:</span>
            <mySelect
              style="width:150px"
              :value="selectInfo.selectVal"
              :optionsList="selectInfo.selectOption"
              placeholder="请选择出品库"
              @selectOptionItem="setSelectValHandle"
              @selectBlurHandle="selectBlurHandle"
              @getOption="getOptionHandle"
            />
          </div>
          <p class="tips">填写商品盘盈盘亏数量</p>
        </div>

        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="space-between center">
              <div class="th">序号</div>
              <div class="th"></div>
              <div class="th">商品名称</div>
              <div class="th">一级分类</div>
              <div class="th">二级分类</div>
              <div class="th">盘盈数量</div>
              <div class="th">盘亏数量</div>
            </div>
          </div>
          <div class="tbody">
            <div class="tr" layout="row" layout-align="space-between center" v-for="(item,index) in tableData" :key="item.key">
              <div class="td">{{index + 1}}</div>
              <div class="td">
                <img class="m-r-2" :src="require('@/assets/img/添加hover.png')" @click="changePrdData('add', index)" />
                <img :src="require('@/assets/img/删除.png')" @click="changePrdData('del', index)" />
              </div>
              <div class="td">
                <el-select v-model="item.prdValue" @change="changePrdInfoHandle(item)" filterable placeholder="请选择">
                  <el-option
                    v-for="item in prdInfoOption"
                    :key="item.value"
                    :label="item.label"
                    :value="item.value">
                  </el-option>
                </el-select>
              </div>
              <div class="td">{{item.firstCategory.name || ''}}</div>
              <div class="td">{{item.secondCategory.name || ''}}</div>
              <div class="td"><input v-model="item.pc" placeholder="请输入盘盈数量" /></div>
              <div class="td"><input v-model="item.ic" placeholder="请输入盘亏数量" /></div>
            </div>
          </div>
        </div>
      </div>
      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_money from "@/api/money";
import common_order from "@/utils/common/order";

import mySelect from "@/components/book/select";

export default {
  data() {
    return {
      show: false,
      selectInfo: {
        selectVal: "",
        prdId:'',
        selectOption: [],
        originSelectOption: []
      },
      canDoPrdList: [],// 可点商品
      tableData: [
        {
          key: +new Date() + 1,
          prdValue: '',
          firstCategory: {},
          secondCategory: {},
          pc: '',
          ic: ''
        },
        {
          key: +new Date() + 2,
          prdValue: '',
          firstCategory: {},
          secondCategory: {},
          pc: '',
          ic: ''
        },
        {
          key: +new Date() + 3,
          prdValue: '',
          firstCategory: {},
          secondCategory: {},
          pc: '',
          ic: ''
        }
      ]
    };
  },
  methods: {
    initData(rest=true){
      if(rest) this.selectInfo.selectVal = ''
      this.tableData = [
        {
          key: +new Date() + 1,
          prdValue: '',
          firstCategory: {},
          secondCategory: {},
          pc: '',
          ic: ''
        },
        {
          key: +new Date() + 2,
          prdValue: '',
          firstCategory: {},
          secondCategory: {},
          pc: '',
          ic: ''
        },
        {
          key: +new Date() + 3,
          prdValue: '',
          firstCategory: {},
          secondCategory: {},
          pc: '',
          ic: ''
        }
      ]
    },
    // 改变商品
    changePrdInfoHandle(itemInfo){
      itemInfo.firstCategory = this.prdInfoOption.find(item => item.id == itemInfo.prdValue).firstCategoryInfo
      itemInfo.secondCategory = this.prdInfoOption.find(item => item.id == itemInfo.prdValue).secondCategoryInfo
    },
    // 增加或删除商品
    changePrdData(type, index){
      switch (type) {
        case 'add':

          this.tableData.push({
            key: +new Date(),
            prdValue: '',
            firstCategory: {},
            secondCategory: {},
            pc: '',
            ic: ''
          })

          break

        case 'del':

          if (this.tableData.length == 1) return this.$message.warning('仅剩一条数据，不可删除')
          this.tableData.splice(index, 1)

          break
      }
    },

    onCancelDrawer() {
      this.$emit("showOrHideAddProfitPrdDrawerHandle");
    },

    async onSubmit(){
      if(!this.selectInfo.prdId) return this.$message.warning('请选择出品库')
      
      const resultPrdList = this.tableData.filter(item => item.prdValue)
      if(resultPrdList.length == 0) return this.$message.warning('请选择商品')

      try {
        const params = {
          mklib_id: this.selectInfo.originSelectOption.find(item => item.name == this.selectInfo.selectVal).id * 1, //   int64   出品库Id
          prd_ids: resultPrdList.map(item => item.prdValue * 1), //    []int64   待操作商品列表
          prd_profit_cnts: resultPrdList.map(item => item.pc * 1), // []int     对应prd_ids的商品盘盈数量,没有填0
          prd_loss_cnts: resultPrdList.map(item => item.ic * 1), // []int     对应prd_ids的商品盘亏数量,没有填0
        }
        
        const res = await api_money.reqAddProfitData(params)

        if(res.code == 1) {
          this.onCancelDrawer();
          this.$emit('getTableData');
        } else {
          this.$message.warning(res.msg);
        }

      } catch (error) {
        console.log('提交盘盈盘亏数据失败', error)
      }
    },

    
    /*
    筛选下拉框相关 start
    */

    getSelectOption(){
      this.selectInfo.originSelectOption = this.$store.state.cardPageInfo.resResultDataObj.outputLibrary.filter(item => item.status == 1)
    },

    setSelectValHandle(info) {
      this.selectInfo.selectVal = info.name;
      this.selectInfo.prdId = (this.selectInfo.originSelectOption.find(item => item.name == this.selectInfo.selectVal) || {}).id
      this.initData(false)

      // 获取当前出品库下可点商品
      const prdIdList = this.$store.state.cardPageInfo.resResultDataObj.areaProduct.filter(item => item.status == 1 && item.mklib_id == this.selectInfo.prdId).map(item => item.prd_id)

      // 可点商品
      const prdInfoList = []
      
      const allPrdList = this.$store.state.cardPageInfo.resResultDataObj.goodsAroundInfo.filter(item => item.status == 1)
      new Set(prdIdList).forEach(el => {
        const find = allPrdList.find(item => item.id == el)
        if(find) prdInfoList.push(find)
      })

      this.canDoPrdList = [...prdInfoList]
      
    },

    selectBlurHandle() {
      this.selectInfo.selectOption = [];
    },
    
    getOptionHandle() {
      this.selectInfo.selectOption = JSON.parse(
        JSON.stringify(this.selectInfo.originSelectOption)
      );
    },
    /*
    筛选下拉框相关 end
    */
  },
  mounted() {
    this.getSelectOption();
  },
  computed: {
    prdInfoOption(){
      const option = this.canDoPrdList.filter(item => item.matId != 0).map(item => ({
        ...item,
        label: item.name,
        value: item.id,
        ...common_order.getPrdCategoryInfo(item.oneCateId, item.twoCateId)
      }))
      return option
    }
  },
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    }
  },
  components: {
    mySelect
  },
  watch: {
    showDrawer: {
      handler(newVal) {
        this.show = newVal;
        if(newVal) this.initData();
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/money/drawerAddProfitPrd.less";
@import "../../../style/common/elementDrawer.less";
@import "../../../style/common/elementFormBtn.less";
@import "../../../style/common/scrollBar.less";
</style>

<style>
.el-scrollbar .el-scrollbar__view.el-select-dropdown__list{
  background-color: #2A3959;
}
.el-select-dropdown__empty{
  background-color: #2A3959;
}
</style>

<style scoped>
.el-select-dropdown__item{
  color: rgba(255, 255, 255, .8);
  font-size: 14px;
}
.el-select-dropdown__item.hover, .el-select-dropdown__item:hover{
    background-color: rgba(90, 90, 90, 0.5)!important;
}
</style>