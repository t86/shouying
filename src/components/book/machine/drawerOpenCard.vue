<template>
  <div class="opencard">
    <el-drawer
      title="开台记录"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      size="90%"
    >
      <p class="white p-t-4 p-b-4 p-l-6 fs14">最近刷新时间：{{loadTime}}</p>
      <div class="search white p-l-6 p-b-4" layout="row" layout-align="space-between center">
        <div layout="row" layout-align="start center">
          <div class="search-item m-r-4" layout="row" layout-align="start center">
          <span>排序：</span>
          <mySelect
            style="width:140px;height:30px;line-height:30px"
            :value="typeName"
            :optionsList="typeList"
            @selectOptionItem="setSelectValHandle"
            @selectBlurHandle="selectBlurHandle"
            @getOption="getOptionHandle"
          />
        </div>
        <el-cascader
            style="width:150px"
            v-model="selDepValue"
            :options="depTree"
            collapse-tags
            :props="{checkStrictly: true}"
            size="mini"
            clearable
          ></el-cascader>
        <input style="margin-left: 10px;" v-model="keyword" placeholder="卡台标记/台位/订位人/客户姓名/电话" />
        <button class="search" @click="getTableData">查询</button>
        <button class="reset" @click="resetSearchVal">重置</button>
        </div>
        <button class="export m-r-6" @click="exportExcelHandle">导出Excel</button>
      </div>
      <!-- 订单表格 -->
      <div class="table">
        <div class="content">
          <div class="thead">
            <div class="tr">
              <div class="th">序号</div>
              <div class="th w80">区域</div>
              <div class="th w150">卡台名称</div>
              <div class="th w120">订位人部门</div>
              <div class="th w120">订位人</div>
              <div class="th w80">卡台标记</div>
              <div class="th w80">低消进度</div>
              <div class="th w120" 
                v-if="!safeModeEnabled && ($store.state.cardPageInfo.resResultDataObj.showAmt.find(item => item.id == 3) ? 
                $store.state.cardPageInfo.resResultDataObj.showAmt.find(item => item.id == 3).param1 == 2 : true)"
                >点单金额</div>
              <div class="th w120">客人电话</div>
              <div class="th w90">客人姓名</div>
              <div class="th w90">客人人数</div>

              <div class="th w120">订位人电话</div>
              <div class="th w120">订位人工号</div>
              <div class="th w170">开台时间</div>
              <div class="th w170">清台时间</div>
              <div class="th w170">联合订位人</div>
              <div class="th w170">联合订位人部门</div>
              <div class="th w200">备注</div>
              <div class="th w150">咨客</div>
            </div>
          </div>
          <div class="tbody" ref="scrollDom">
            <div
              v-if="tableData.length==0"
              style="text-align:center;transform:translateY(40px)"
            >暂无数据</div>
            <div v-else ref="scrollItem">
              <div class="coll" v-for="(item,i) in tableData" :key="i">
                <div class="detail tr">
                  <div class="td">{{i+1}}</div>
                  <div class="td w80">{{item.rn}}</div>
                  <div class="td w150">{{item.sn}}</div>
                  <div class="td w120">{{item.sd}}</div>
                  <div class="td w120">{{item.sen}}</div>
                  <div class="td w80">{{item.m}}</div>
                  <div class="td w80">{{item.mp + '%'}}</div>
                  <div class="td w120" 
                    v-if="!safeModeEnabled && ($store.state.cardPageInfo.resResultDataObj.showAmt.find(item => item.id == 3) ?
                    $store.state.cardPageInfo.resResultDataObj.showAmt.find(item => item.id == 3).param1 == 2 : true)"
                    >{{(item.om / 100).toFixed(2)}}</div>
                  <div class="td w120">{{item.cp}}</div>
                  <div class="td w90">{{item.cn}}</div>
                  <div class="td w90">{{item.cc}}</div>
                  <div class="td w120">{{item.sp}}</div>
                  <div class="td w120">{{item.sc}}</div>
                  <div class="td w170">{{item.ot}}</div>
                  <div class="td w170">{{item.tt}}</div>
                  <div class="td w170">{{item.s}}</div>
                  <div class="td w170">{{item.d}}</div>
                  <div class="td w200">{{item.r}}</div>
                  <div class="td w200">{{item.on}}</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import api_book from "@/api/Book";
import mySelect from "@/components/book/select";
import { cloneDeep } from "lodash-es";

let originSelectOption = [];
let originPersonList = [];  // 原始的所有有效订位人id
export default {
  data () {
    return {
      show: false,
      loadTime: '',
      typeName: '按开台时间排序',
      typeOriginList: [
        {
          id: 1,
          name: '按开台时间排序'
        },
        {
          id: 2,
          name: '按部门员工排序'
        },
        {
          id: 3,
          name: '按区域排序'
        }
      ],
      typeList: [],
      selectVal: "全部",
      selectOption: [],
      personVal: [-1, -1],
      personOptions: [],
      tableData: [],
      keyword: '',
      selDepValue: ['0'],
      depTree: []
    };
  },
  methods: {
    // format (number) {
    //   if (number == 0) return number.toString();
    //   number = number.toString();

    //   let decimalIndex = number.length - 2;
    //   return number.substring(0, decimalIndex) + "." + number.substring(decimalIndex);
    // },
    getReloadTime () {
      const date = new Date();
      const Y = date.getFullYear();
      const M = (date.getMonth() + 1).toString().padStart(2, 0);
      const D = date.getDate().toString().padStart(2, 0);
      const hour = date.getHours().toString().padStart(2, 0);
      const minute = date.getMinutes().toString().padStart(2, 0);
      const second = date.getSeconds().toString().padStart(2, 0);
      this.loadTime = `${Y}-${M}-${D} ${hour}:${minute}:${second}`
    },

    async getSelectOption () {
      this.typeList = [...this.typeOriginList]
    },

    async getTableData () {
      this.getReloadTime();
      const params = {
        key: this.keyword,//Key 模糊查询关键字,卡台标记,订位人,客人电话,客人姓名
        dept_id: (this.selDepValue[0] || '0') * 1,
        type_id: this.typeOriginList.find(item => item.name == this.typeName).id  //typeId 1 按开台时间排序   2 按部门员工排序  3 按区域排序}
      }
      try {
        const res = await api_book.reqOpenCardListData(params);
        if (res.code == 1) {
          // res.data.records = res.data.records || [];
          this.tableData = res.data.records || [];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {

      }
    },

    resetSearchVal () {
      this.selectVal = "全部";
      this.personVal = [-1, -1];
      this.getTableData();
    },

    async exportExcelHandle () {
      const params = {
        key: this.key, //
        type_id: this.typeOriginList.find(item => item.name == this.typeName).id
      }

      try {
        const res = await api_book.reqExportOpenCardExcel(params);
        if (!res.msg) {
          const url = window.URL.createObjectURL(
            new Blob([res], {
              type:
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            })
          );
          const a = document.createElement("a"); //添加a标签
          document.body.appendChild(a);
          a.href = url;
          a.setAttribute("download", decodeURIComponent(res.fileName)); // 下载文件的名称及文件类型后缀
          a.click(); //点击标签
          document.body.removeChild(a); // 下载完成移除元素
          window.URL.revokeObjectURL(url); // 释放掉blob对象
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("导出excel失败", error);
      }
    },

    closeDrawerHandle () {
      this.$emit("showOrHideDrawer", false);
    },

    onCancelDrawer () {
      this.closeDrawerHandle();
    },

    getDepTree () {

      let departmentList = cloneDeep([{id: '0', name:'不限', parentId: 0 }, ...this.$store.state.cardPageInfo.resResultDataObj.departmentInfo]);
      this.depTree = this.listToTree(departmentList); // list为原始列表数据
    },

    listToTree (newList) {
      const map = {};
      let node = [];
      for (let i = 0; i < newList.length; i++) {
        map[newList[i].id] = i; 
      }

      for (let i = 0; i < newList.length; i++) {
        const cur = {...newList[i], label: newList[i].name, value: newList[i].id};
        if (cur.parentId * 1 == 0) {
          node.push(cur);
        } else {
          if (newList[map[cur.parentId]] && !newList[map[cur.parentId]].children) {
            newList[map[cur.parentId]].children = [];
          }
          newList[map[cur.parentId]].children.push(cur);
        }
      }

      return node;
    },

    // 生成部门-员工option
    getPersonSelectOption (personList = []) {
      const personOption = [{
        value: -1,
        label: '全部',
        namePy: 'qb',
        children: [{
          value: -1,
          code: -1,
          label: '全部',
          namePy: 'qb'
        }]
      }];
      if (personList.includes(0)) {
        personOption.push({
          value: 0,
          label: '散客',
          namePy: 'sk',
          children: [{
            value: 0,
            code: 0,
            label: '散客',
            namePy: 'sk'
          }]
        })
      }
      const personListResult = this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo.filter(item => personList.includes(item.id * 1));

      const departmentListResult = []  // 有效部门列表
      personListResult.forEach(el => {
        const department = this.$store.state.cardPageInfo.resResultDataObj.departmentInfo.find(item => item.id == el.deptId)
        if (department && !departmentListResult.find(item => item.id == department.id)) departmentListResult.push(department)
      });

      // 给部门添加有效员工
      departmentListResult.forEach(el => {
        el.value = el.id;
        el.label = el.name;
        el.children = personListResult.filter(item => item.deptId == el.id).map(item => ({
          ...item,
          value: item.id,
          label: item.name,
        }))
      })
      // console.log('personListResult',personListResult)
      // console.log('departmentListResult',departmentListResult)
      this.personOptions = [...personOption, ...departmentListResult]
    },

    initSelectOption (areaIdList = []) {
      const areaList = this.$store.state.cardPageInfo.resResultDataObj.areaInfo.filter(item => areaIdList.includes(item.id * 1));
      if (!areaList.find(item => item.id === 0)) areaList.unshift({ id: 0, name: "全部" });
      originSelectOption = [...areaList];
    },
    setSelectValHandle (info) {
      this.typeName = info.name;
    },
    selectBlurHandle () {
      this.typeList = [];
    },
    getOptionHandle () {
      this.typeList = [...this.typeOriginList];
    }
  },
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    },
    safeModeEnabled: {
      type: Boolean,
      default: false
    }
  },
  components: {
    mySelect
  },
  watch: {
    showDrawer (newVal) {
      this.show = newVal;
      if (newVal) {
        this.getSelectOption();
        this.getDepTree();
        this.resetSearchVal();
      };
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawer.less";
@import "../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../style/common/elementFormBtn.less";
@import "../../../style/common/scrollBar.less";
@import "../../../style/book/machine/drawerOpenCard.less";
</style>

<style scoped lang="less">
/deep/.select-com {
  font-size: 14px;
}

/deep/.options li {
  font-size: 14px;
}
</style>

<style>
.el-cascader__dropdown {
  background-color: #202c4a !important;
  color: rgba(255, 255, 255, 0.8);
}

.el-cascader-node {
  color: rgba(255, 255, 255, 0.8);
  font-size: 14px;
}

.el-cascader-node:not(.is-disabled):focus,
.el-cascader-node:not(.is-disabled):hover {
  background-color: rgba(90, 90, 90, 0.5) !important;
}

.el-cascader-panel {
  border: none;
}
</style>