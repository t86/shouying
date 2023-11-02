<template>
  <div class="day-report">
    <div class="header white p-l-4 p-r-4" layout="row" layout-align="space-between center">
      <span>套餐统计表</span>
      <i class="el-icon-close" @click="onClose"></i>
    </div>
    <div class="session white" layout="row" layout-align="space-between center">
      <div class="session-left" layout="row" layout-align="space-around center">
        <div class="session-left-contain">
          <h4>选择统计的套餐</h4>
          <div class="session-left-contain-checkbox">
            <el-tree 
              ref="treeRef"
              :data="catData" 
              default-expand-all
              show-checkbox 
              node-key="id" 
              :default-checked-keys="selectedKeys"
              :props="defaultProps"
              multiple
            >
          </el-tree>
          </div>
        </div>
      </div>
      <div class="session-center" layout="row" layout-align="center center">
        <div class="session-center-contain">
          <div layout="row" layout-align="center center">
            <span class="m-r-2">订单类型</span>
            <mySelect
              style="width:50%"
              :value="orderType"
              :optionsList="orderList"
              @selectOptionItem="setSelectValHandle"
              @selectBlurHandle="selectBlurHandle"
              @getOption="getOptionHandle"
            />
          </div>
          <div class="m-t-4" layout="row" layout-align="center center">
            <button class="primary" @click="getTableData">统计</button>
          </div>
          <div class="m-t-4" layout="row" layout-align="center center">
            <button class="primary" @click="printTableData">打印</button>
          </div>
          <div class="m-t-4" layout="row" layout-align="center center">
            <button class="cancel" @click="onClose">关闭</button>
          </div>
        </div>
      </div>
      <div class="session-right">
        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="start center">
              <div class="th">商品名称</div>
              <div class="th">售出数量</div>
            </div>
          </div>
          <div class="tbody">
            <div
              class="tr"
              layout="row"
              layout-align="start center"
              v-for="(item, index) in tableData"
              :key="index"
            >
              <div class="td">{{item.n}}</div>
              <div class="td">{{item.c}}</div>
            </div>
            <p v-if="tableData.length == 0" class="m-t-10 fs14" style="text-align:center">暂无数据</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
 
<script>
import api_money from "@/api/money";
import mySelect from "@/components/book/select";
export default {
  data() {
    return {
      defaultProps: {
        label: 'n',
        children: 'ss'
      },
      tableData: [],
      catData: [],
      selectedKeys: [],
      orderType: '全部订单',
      orderList: [],
      orgOrderList:[
        {
          id: 0,
          name: '全部订单'
        },
        {
          id: 1,
          name: '未结订单'
        },
        {
          id: 2,
          name: '已结订单'
        },
      ]
    };
  },
  methods: {

    onClose(){
      this.$emit('showOrHideSetCountDrawerHandle')
    },
    /*
    筛选下拉框相关 start
    */
    setSelectValHandle(info) {
      this.orderType = info.name;
    },
    selectBlurHandle() {
      this.orderList = [];
    },
    getOptionHandle() {
      this.orderList = JSON.parse(
        JSON.stringify(this.orgOrderList)
      );
    },
    /*
    筛选下拉框相关 end
    */


    // 获取二级分类及出品库
    async getTableData() {
      try {
        // 读取可打印二级分类和套餐项
        const res = await api_money.reqGetSetCntItems();
        if (res.code == 1) {
          this.catData = res.data.two_cates || []
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取表格数据失败", error);
      }

      console.log(this.catData)
    },

    async printTableData() {
      const params = {
        two_cate_ids: this.secondCategoryInfo.checkedAll
          ? [0]
          : this.secondCategoryInfo.list
              .filter(item => item.checked)
              .map(item => item.id * 1), // []int64   二级分类列表,如果是全部,传一个元素为0的数组
        mklib_ids: this.outLibraryInfo.checkedAll
          ? [0]
          : this.outLibraryInfo.list
              .filter(item => item.checked)
              .map(item => item.id * 1), //  []int64   出品库列表,如果是全部,传一个元素为0的数组
        settle_type: this.selectInfo.originSelectOption.find(
          item => item.name == this.selectInfo.selectVal
        ).id // int     订单类型, 0 全部 1 已结账 2 未结账
      };

      if (params.two_cate_ids.length == 0)
        return this.$message.warning("请选择二级分类筛选条件");
      if (params.mklib_ids.length == 0)
        return this.$message.warning("请选择出品库筛选条件");

      try {
        const res = await api_money.reqPrintDayReport(params);
        if (res.code == 1) {
          this.$message.success('打印成功');
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("打印售出报表失败", error);
      }

    },

    changeSelectHandle(type1, type2) {
      const info =
        type1 == "category" ? this.secondCategoryInfo : this.outLibraryInfo;
      if (type2 == "all") {
        info.list.forEach(el => {
          el.checked = info.checkedAll;
        });
      } else {
        info.checkedAll = info.list.every(item => item.checked);
        info.indeterminate =
          !info.checkedAll && info.list.some(item => item.checked);
      }
    }
  },
  async mounted() {
    await this.getTableData();
  },
  components: {
    mySelect
  },
};
</script>

<style scoped lang="less">
.day-report {
  background: #202C4A;
  // background: linear-gradient(180deg, #202C4A 0%, #2A3959 100%);

  .header {
    height: 48px;
    background:#222D47;
    // background: linear-gradient(180deg, #222D47 0%, #11182D 100%);
  }

  .session {

    &-left {
      width: 20%;

      &-contain {
        width: 100%;
        border: 1px solid #999;
        border-radius: 10px;
        padding: 10px;
        box-sizing: border-box;

        h4 {
          line-height: 40px;
        }

        &-checkbox {
          overflow-y: auto;
          height: calc(100vh - 150px);
        }
      }
    }

    &-center {
      width: 20%;
      padding-bottom: 5%;

      &-contain {
        width: 100%;

        button {
          cursor: pointer;
          color: #fff;
          width: 120px;
          height: 40px;
          border-radius: 20px;
          border: none;

          &.primary {
            background: #4b89ff;
            // background: linear-gradient(180deg, #4b89ff 0%, #455eff 100%);
            box-shadow: inset 0px 1px 1px 0px rgb(255 255 255 / 50%);
          }

          &.cancel {
            background: #374368;
            box-shadow: inset 0px 1px 1px 0px rgb(255 255 255 / 30%);
          }
        }
      }
    }

    &-right {
      width: 60%;
      padding: 20px;
      box-sizing: border-box;
      .table{
        border: 1px solid #999;
        border-radius: 10px;
        height: calc(100vh - 90px);
        overflow-y: auto;
        .tr{
          padding: 0 20px;
          box-sizing: border-box;
          height: 36px;
          line-height: 36px;
          font-size: 14px;
        }
        .thead{
          position: sticky;
          top: 0;
          background: #182037;
          // background: linear-gradient(180deg, #182037 0%, #11182D 100%);
          color: rgba(255, 255, 255, .5);
        }
        .tbody{
          color: rgba(255, 255, 255, .8);
          .tr:nth-child(2n){
            background-color: rgba(255, 255, 255, 0.04);
          }
        }

        .th:nth-child(1), .td:nth-child(1){
          width: 70%;
        }
        .th:nth-child(2), .td:nth-child(2){
          width: 30%;
        }
      }
    }
  }
}

/deep/.el-checkbox__label {
  color: #fff;
}

/deep/.select-com,
/deep/.options{
  border-color: #999!important;
}

/deep/.select-com,
/deep/.options li {
  font-size: 14px;
  height: 28px;
  line-height: 28px;
}

/deep/.el-tree__empty-block {
  background-color: #202C4A;
}

/deep/.el-tree__empty-text {
  color: rgba(255, 255, 255, 0.8);
}
/deep/.el-tree {
  background-color: #202C4A;
  color: rgba(255, 255, 255, 0.8);
}

/deep/.el-tree-node__content:hover, .el-upload-list__item:hover {
  background-color: rgba(30, 30, 30, 0.8);
}
</style>