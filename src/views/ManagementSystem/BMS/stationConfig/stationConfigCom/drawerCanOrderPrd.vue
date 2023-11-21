<template>
  <div>
    <!-- 可点商品 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5 erp-lib-detail fs14 tab">
        <div class="item item-left" :class="{isActive: isCanOrder}" @click.stop="onChangeTab(1)">配置可点分类</div>
        <div class="item item-right" :class="{isActive: !isCanOrder}" @click.stop="checkChangeTab">配置不可点分类</div>
      </div>
      <div class="session p-5 erp-lib-detail fs14" v-if="isCanOrder">
        <p class="red-color">
          说明：勾选“全部”后，如果有新增分类，该新增的分类默认选中
        </p>
        <p class="red-color m-l-10 p-l-2 m-t-3 m-b-3">
          勾选“以下全部勾选”，如果有新增分类，该新增的分类默认不选中
        </p>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="fs14">可点商品：</span>
          </div>
          <div class="value">
            <el-checkbox
              v-model="checkAll"
              :indeterminate="indeterminate"
              @change="checkAllHandle($event)"
              >全部</el-checkbox
            >
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start start">
          <div class="label">
            <span class="fs14">选择可点商品：</span>
          </div>
          <div class="value" layout="row" layout-align="start center">
            <classifyTree
              :treeData="waiterCates"
              :resetStatus="resetStatus"
              @onChange="waiterCatesChange"
            />
          </div>
        </div>
      </div>
      
      <div class="session p-5 erp-lib-detail fs14" v-if="!isCanOrder">
        <div class="coll p-b-3 border-bottom">
          <div class="value m-t-3 m-l-8">
            <el-button type="primary" size="small" @click.native="showAddPrdDrawer = true">新增商品</el-button>
            <el-button type="primary" size="small" @click.native="deleteHandle">批量删除</el-button>
          </div>
        </div>
        <div class="table-content m-t-3">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">
                  <el-checkbox
                    v-model="unPrdcheckAll"
                    :indeterminate="isIndeterminate"
                    @change="changeCheckboxHandle('all')"
                  >全选</el-checkbox>
                </div>
                <div class="th">单品</div>
                <div class="th">分类</div>
                <div class="th">单价</div>
              </div>
            </div>
            <div class="tbody">
              <div
                class="tr"
                v-for="(item, index) in tableData"
                :key="item.id"
                layout="row"
                layout-align="space-between center"
              >
                <div class="td">
                  <el-checkbox
                    v-model="item.checked"
                    @change="changeCheckboxHandle('item')"
                  >{{index + 1}}</el-checkbox>
                </div>
                <div class="td">{{item.n}}</div>
                <div class="td">{{item.tn}}</div>
                <div class="td">{{item.p}}</div>
              </div>
              <div class="no-data" v-if="tableData.length==0">
                <img :src="require('@/assets/img/wu.png')" alt />
                <p>暂无数据</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 添加商品 -->
      <drawerAddPrd v-model="showAddPrdDrawer" @getChoosedPrdList="getChoosedPrdList" :stationId="checkedList.map((item) => item.id * 1)[0]" prdType="2" :checkedPrdList="tableData" />


      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
        <el-button type="primary" @click="onSubmit(false)" v-if="isCanOrder">确定</el-button>
      </div>
    </el-drawer>

    <el-dialog title="确认保存" :visible.sync="dialogSaveVisible" width="30%">
        <p style="line-height:40px">可点商品信息尚未保存，是否确定保存？</p>
        <span slot="footer" class="dialog-footer">
          <el-button @click="dialogSaveVisible = false; onChangeTab(2)">否</el-button>
          <el-button type="primary" @click="saveAndChange">是</el-button>
        </span>
      </el-dialog>
  </div>
</template>

<script>
import { cloneDeep } from "lodash-es";
export default {
  data() {
    return {
      isCanOrder: true,
      checkAll: false,
      indeterminate: false,
      resetStatus: false,
      waiterCates: [], // 树形结构
      originCates: [],
      originCheckAll: false,
      showAddPrdDrawer: false,
      tableData: [],
      unPrdcheckAll: false,
      dialogSaveVisible: false,
    };
  },
  methods: {
    getChoosedPrdList(prdList){
      console.log('getChoosedPrdList')
      this.tableData = [...this.tableData, ...prdList].filter((item, index, arr) => arr.findIndex(items => items.id == item.id) == index)
      this.unPrdcheckAll = this.tableData.every(item => item.checked)
    },
    // 删除
    async deleteHandle() {
      console.log('deleteHandle')
      const checkedIdList = this.tableData.filter(item => item.checked).map(item => item.id)

      const res = await this.$api.BMS.station.reqDelOrdExclPrd({
        station_id: this.checkedList.map((item) => item.id * 1)[0],
        prd_ids: checkedIdList
      });
      if (res.code == 1) {
        this.$message.success("批量删除成功");
        const tableData = []
        this.tableData.forEach(el => {
          if(!checkedIdList.find(item => item == el.id)) tableData.push(el)
        })
        this.tableData = [...tableData]
        this.checkAll = false
      } else {
        this.$message.warning(res.msg);
      }
    },
    changeCheckboxHandle(type) {
      console.log('changeCheckboxHandle', type)
      switch (type) {
        case "all":
          this.tableData = this.tableData.map(item => ({
            ...item,
            checked: this.unPrdcheckAll
          }));
          break;
        case "item":
          this.unPrdcheckAll = this.tableData.every(item => item.checked);
          break;
      }
    },

    filter(arr) {
      const result = [];

      for (let i = 0; arr && i < arr.length; i++) {
        const item = arr[i];
        if (item.c) {
          result.push(item);
        } else {
          // 递归过滤子节点
          const subs = this.filter(item.subs);  
          if (subs.length > 0) {
            // 如果子节点有过滤结果,则构造一个新的对象
            result.push({
              id: item.id,
              subs: subs
            });
          }
        }
      }
      return result;
    },
    equal(arr1, arr2) {
      const filtered1 = this.filter(arr1);
      const filtered2 = this.filter(arr2);
      // 数组长度不一样则不相等
      if (filtered1.length !== filtered2.length) {
        return false;
      }
      // 遍历每一个元素进行深度比较
      for (let i = 0; i < filtered1.length; i++) {
        if (!this.deepEqual(filtered1[i], filtered2[i])) { 
          return false;
        }
      }
      return true;
    },
    // 比较两个树形数据结构
    deepEqual(o1, o2) {
        // 比较根节点 id 和 c
        if (o1.id !== o2.id || o1.c != o2.c) {
          return false;
        }
        for (let i = 0; o1.subs && i < o1.subs.length; i++) {
          if (!this.deepEqual(o1.subs[i], o2.subs[i])) {
            return false;
          }
        }
        return true;
    },
    checkChangeTab(){
      if(this.checkAll != this.originCheckAll) {
        this.dialogSaveVisible = true
        return
      }
      const mustMatch = this.equal(this.originCates, this.waiterCates);
      if (!mustMatch){
        this.dialogSaveVisible = true
        return
      }
      this.onChangeTab(2)
    },
    saveAndChange(){
      this.dialogSaveVisible = false
      this.onSubmit(false);
      this.onChangeTab(2)
    },
    async onChangeTab(type) {
     
      if(type === 2){
        if(this.checkedList.map((item) => item.id * 1).length > 1) {
          this.$message.warning('不可点商品暂不支持批量设置');
          return
        }
        const res = await this.$api.BMS.station.reqGetOrdExclList({station_id: this.checkedList.map((item) => item.id * 1)[0]})
        if (res.code == 1) {
          if (res.data.records && res.data.records.length > 0) {
            this.tableData = res.data.records.map(item => ({
              ...item,
              checked: true
            }))
          } else {
            this.tableData = []
          }
        } else {
          this.onChangeTab(1)
          this.$message.warning(res.msg);
        }
      } else {
        if(this.checkAll) {
          this.checkAllHandle(true)
        }
      }
      this.isCanOrder = type === 1
    },
    async getDetail() {
      const params = {
        station_ids: this.checkedList.map((item) => item.id * 1),
      };
      try {
        const res = await this.$api.BMS.station.requestStationWaiterCates(
          params
        );
        if (res.code == 1) {
          this.waiterCates = (res.data.cates || []).map((item) => ({
            ...item,
            subs: (item.subs || []).map((items) => ({
              ...items,
              ost: items.st,
              c: items.st == 1,
            })),
          }));

          setTimeout(() => {
            this.indeterminate = res.data.all_sel_type == 3;
            this.checkAll = res.data.all_sel_type == 1;
            this.originCheckAll = this.checkAll
          });
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("数据请求失败", error);
      }
    },

    // 点击可点商品全部checkbox
    checkAllHandle(val) {
      setTimeout(() => {
        this.checkAll = val;
        this.indeterminate = false;
      });
      if (val) {
        this.resetStatus = !this.resetStatus;
        this.waiterCates.map((item) => {
          item.st = 2;
          item.c = false;
          if (item.subs) {
            item.subs.map((v) => {
              v.st = 2;
              v.c = false;
            });
          }
        });
      }
    },

    //监测可点商品数据变化
    waiterCatesChange(data) {
      this.waiterCates = data;
      if(this.originCates.length == 0) {
        this.originCates = cloneDeep(this.waiterCates);
      }
      this.indeterminate = false;
      this.checkAll = false;
    },

    async onSubmit(isClose = true) {
      if(this.isCanOrder) {
        let selCates = [];
        let unChangeCates = [];
        let selected = [];
        let allPrdMode = 2;
        this.waiterCates.forEach((el) => {
          (el.subs || []).forEach((ele) => {
            if (ele.ost == ele.st && ele.st != 2) {
              unChangeCates.push(ele.id);
          }
          if (ele.ost != ele.st && ele.st == 1) {
                selCates.push(ele.id);
          }
          if (ele.st != 2) {
                selected.push(ele.id);
            }
          });
        });

        if (this.checkAll) {
          allPrdMode = 1;
        } else if (!this.indeterminate && !this.checkAll) {
          allPrdMode = 2;
        } else {
          allPrdMode = 3;      
        }

        const params = {
          station_ids: this.checkedList.map((item) => item.id * 1),        
          all_prd_mode: allPrdMode,
          sel_cates: selCates,        
          unchange_cates: unChangeCates,
        };
        try {
          const res = await this.$api.BMS.station.requestStationSaveWaitCates(
          params
          );
          if (res.code == 1) {
            this.$message.success("操作成功");
            this.originCates = cloneDeep(this.waiterCates);
            this.originCheckAll = this.checkAll
            if(isClose) {
              this.onCancelDrawer();
            }
            this.$emit("getTableData");
          } else {
            this.$message.warning(res.msg);
          }
        } catch (error) {
          console.log("数据请求失败", error);
        }
      }
    },

    onCancelDrawer() {
      this.show = false;
      this.isCanOrder = true;
      this.waiterCates = []
      this.originCates = []
      this.checkAll = false
      this.originCheckAll = false
      this.tableData = []
      this.unPrdcheckAll = false
    },
  },
  mounted() {},
  props: {
    value: {
      default: false, // 是否显示drawer
    },
    checkedList: {
      default: () => [],
    },
  },
  computed: {
    title() {
      return "可点商品";
    },

    show: {
      get() {
        return this.value;
      },

      set(val) {

        this.$emit("input", val);
      },
    },
    isIndeterminate() {
      return !this.checkAll && this.tableData.some(item => item.checked);
    }
  },

  components: {
    classifyTree: () => import("./ClassifyTree.vue"),
    drawerAddPrd: () => import('../../prdGroupConfig/prdGroupCom/drawerAddPrd.vue')
  },

  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.getDetail();
        }
      },
      immediate: true,
    },
  },
};
</script>

<style scoped lang="less">
@import "../../../../../style/common/elementDrawerWine.less";
@import "../../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../../style/common/elementFormBtnWine.less";
@import "../../../../../style/erp/form.less";
@import "../../../../../style/erp/table.less";
</style>

<style lang="less" scoped>

.tab {
  display: flex;
  justify-content: start;
  padding-left: 200px;
  width: 90%;
  .item {
    padding: 10px;
    border: 1px solid #5c5c5c;
    background-color: white;
    align-items: center;
    text-align: center;
    &-left {
      width: 120px;
      border-radius: 20px 0px 0px 20px;

    }
    &-right {
      width: 120px;
      border-radius: 0px 20px 20px 0px;
    }
  }

  .isActive {
    background-color: #c3c3c3;
  }
}
.coll {
  .label {
    width: 120px;
  }
}
</style>
