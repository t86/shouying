<template>
<!-- 过期待处理 -->
  <div class="pass-time">
    <div class="top" layout="row" layout-align="start center">
      <el-input v-model="keyword" style="width:300px" class="m-r-2" size="small" placeholder="输入客人手姓名/手机号/商品/卡台/订位人"></el-input>
      <span>过期天数大于</span>
      <el-input v-model="passDay" style="width:70px" class="m-r-2" size="small" placeholder="数字：单位天"></el-input>
      <el-button type="primary" size="small" @click="getTableData">查询</el-button>
      <el-button size="small" @click="resetHandle">重置</el-button>
    </div>
    <div class="btn-area m-t-4 m-b-2">
      <el-button type="primary" size="small" @click="showLongDrawerHandle">批量延期</el-button>
      <el-button type="primary" size="small" @click="addStoreHandle">批量充公</el-button>
      <el-button type="primary" size="small" @click="exportExcelHandle">导出</el-button>
    </div>
    <span class="color-red">说明：过期充公酒水将进入待充公列表</span>
    <div class="table-content m-t-2">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="start center">
            <div class="th">
              <el-checkbox
                v-model="allChecked"
                :indeterminate="isIndeterminate"
                @change="changeAllCheckboxHandle()"
                >全选</el-checkbox
              >
            </div>
            <div class="th">客人姓名</div>
            <div class="th">联系方式</div>
            <div class="th">卡台</div>
            <div class="th">订台人</div>
            <div class="th">服务员</div>
            <div class="th">存酒时间</div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" v-for="(item, index) in tableData" :key="item.id">
            <div class="coll" layout="row" layout-align="space-between center">
              <div class="td" layout="row" layout-align="start center">
                <span>{{index + 1}}</span>
                <i
                  class="m-l-2"
                  style="border:1px solid #ccc;cursor:pointer"
                  @click="item.show = !item.show"
                  :class="[item.show ? 'el-icon-minus' : 'el-icon-plus']"
                ></i>
              </div>
              <div class="td">{{item.c}}</div>
              <div class="td">{{item.p}}</div>
              <div class="td">{{item.s}}</div>
              <div class="td">{{item.e}}</div>
              <div class="td">{{item.w}}</div>
              <div class="td">{{item.t}}</div>
            </div>
            <div class="detail-list" v-if="item.show">
              <div class="tr-thead" layout="row" layout-align="space-between center">
                <div class="tr-th" layout="row" layout-align="start center">
                  <div style="width:50px;text-align:left">
                    <el-checkbox
                      :indeterminate="item.isIndeterminate"
                      v-model="item.checkAll"
                      @change="changeCheckboxHandle('all', item)"
                    >全选</el-checkbox>
                  </div>
                </div>
                <div class="tr-th">酒水名称</div>
                <div class="tr-th">规格</div>
                <div class="tr-th">每瓶克数</div>
                <div class="tr-th">数量</div>
                <div class="tr-th">延期次数</div>
                <div class="tr-th">过期天数</div>
                <div class="tr-th">过期时间</div>
                <div class="tr-th">授权人</div>
                <div class="tr-th">流水号</div>
                <div class="tr-th">备注姓名</div>
                <div class="tr-th">备注手机号</div>
              </div>
              <div class="tr-tbody">
                <div
                  class="tr-tr"
                  layout="row"
                  layout-align="space-between center"
                  v-for="(items, i) in (item.ss || [])"
                  :key="i"
                >
                  <div class="tr-td" layout="row" layout-align="start center">
                    <div style="width:50px;text-align:left">
                      <el-checkbox
                        v-model="items.checked"
                        @change="changeCheckboxHandle('item', item)"
                      >{{i + 1}}</el-checkbox>
                    </div>
                  </div>
                  <div class="tr-td">{{items.n}}</div>
                  <div class="tr-td">{{items.u}}</div>
                  <div class="tr-td">{{items.g}}</div>
                  <div class="tr-td">{{items.c}}</div>
                  <div class="tr-td">{{items.dc}}</div>
                  <div class="tr-td">{{items.ed}}</div>
                  <div class="tr-td">{{items.e}}</div>
                  <div class="tr-td">{{items.a}}</div>
                  <div class="tr-td">{{items.id}}</div>
                  <div class="tr-td">{{items.rn}}</div>
                  <div class="tr-td">{{items.rp}}</div>
                </div>
              </div>
            </div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img src="@/assets/img/wu.png" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
    </div>
    <!-- 批量延期 -->
    <drawerLongTime v-model="showLongDrawer" :ids="ids" @getTableData="getTableData" />

  </div>
</template>
 
<script>
import { keyHandle } from '../../../../mixin/keyhandle';
import api_wine from '@/api/wine';
import drawerLongTime from '../saveLib/drawerLongTime.vue'
export default {
  data() {
    return {
      ids: [],
      keyword: "",
      passDay: 0,
      tableData: [],
      allChecked: false,
      showLongDrawer: false,  // 延期drawer
      isIndeterminate: false, //
    };
  },
  methods: {
    async getTableData(){
      const params = {
        key: this.keyword || '',  //  string  搜索关键字
        expired_day: this.passDay * 1 // 过期时间
      }

      try {
        const res = await api_wine.reqGetPassTimeNeedToLib(params)
        if (res.code == 1) {
          res.data.records = res.data.records || []
          res.data.records.forEach(el => {
            el.ss = (el.ss || []).map(item => ({
              ...item,
              checked: false,
            }));
            el.show = true;
            el.checkAll = false;
            el.isIndeterminate = false
          });

          this.tableData = res.data.records;
          this.ids = []
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('存酒库过期待处理数据获取失败', error)
      }
    },

    // 批量充公
    async addStoreHandle(){
      if(this.ids.length <=0) return this.$message.warning('请选择需要充公的商品')
      const params = {
        invt_ids: this.ids //  []int64   库存Id列表
      }
      try {
        const res = await api_wine.reqPassPrdToStore(params)
        if (res.code == 1) {
          this.$message.success('已加入待充公列表')
          this.getTableData()
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('充公失败', error)
      }
    },

    // 批量延期
    showLongDrawerHandle(){
      if(this.ids.length <=0) return this.$message.warning('请选择需要延期的商品')
      this.showLongDrawer = true
    },
    changeAllCheckboxHandle() {
      this.tableData.forEach(el => {
        el.checkAll = this.allChecked
        el.ss.forEach(e => {
          e.checked = this.allChecked;
        });
        el.isIndeterminate = !el.checkAll && el.ss.some(item => item.checked);
      });
      const ids = []
      this.tableData.forEach(el => {
        el.ss.forEach(ele => {
          if(ele.checked) ids.push(ele.id)
        })
      })
      this.ids = ids
      this.isIndeterminate = !this.allChecked && ids.length > 0
    },
    changeCheckboxHandle(type, itemInfo) {
      switch (type) {
        case "all":
          itemInfo.ss.forEach(el => {
            el.checked = itemInfo.checkAll;
          });
          break;
        case "item":
          itemInfo.checkAll = itemInfo.ss.every(item => item.checked);
          break;
      }
      
      itemInfo.isIndeterminate = !itemInfo.checkAll && itemInfo.ss.some(item => item.checked);
      const ids = []
      let checkAll = true
      this.tableData.forEach(el => {
        el.ss.forEach(ele => {
          if(ele.checked) ids.push(ele.id)
          else checkAll = false
        })
      })
      this.ids = ids
      this.allChecked = checkAll
      this.isIndeterminate = !this.allChecked && ids.length > 0
    },

    resetHandle() {
      this.keyword = "";
      this.getTableData();
    },
    
    async exportExcelHandle(){
      const params = {
        key: this.keyword  //  string   商品名称关键字 
      }
      try {
        const res = await api_wine.reqExportWineInvtExpired(params);
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
  },
  created() {
    this.getTableData()
  },
  computed: {
    isIndeterminate() {
      return !this.allChecked && this.tableData.some(item => item.checked);
    }
  },
  mixins: [keyHandle],
  components: {
    drawerLongTime
  },
};
</script>

<style lang="less" scoped>
@import "../../../../style/wine/table.less";
</style>
<style scoped lang="less">
.pass-time {
  padding: 20px;
  .table-content {
    .table {
      .tbody {
        height: calc(100vh - 260px);
        overflow: auto;
        .tr {
          background-color: #ddd!important;
          margin-top: 2px;
          .td {
            background-color: #ddd!important;
          }
          &:hover{
            .td {
              background-color: #ddd!important;

            }
          }
        }
        .coll {
          height: 40px;
          font-size: 15px;
          
          .td {
            font-weight: 600;
            /deep/.el-checkbox__label{
              font-weight: 600;
            }
            &:nth-last-child(1) {
              span {
                color: #2170ff;
                cursor: pointer;
              }
            }
          }
        }
        .detail-list {
          font-size: 14px;
          .tr-thead {
            height: 30px;
            width: 100%;
            background-color: #eee;
            .tr-th {
              font-weight: 600;
              width: 50%;
              color: #6A6A74;
              &:nth-child(1){
                padding-left: 20px;
                /deep/.el-checkbox__label{
                  font-weight: 600;
                  color: #6A6A74;
                }
              }
            }
          }
          .tr-tbody {
            // max-height: 200px;
            // overflow: auto;
            .tr-tr{
              min-height: 30px;
              &:hover{
                background-color: #d7e9ff!important;
              }
              &:nth-child(2n){
                background-color: #eee;
              }
              &:nth-child(2n + 1){
                background-color: #f9f9f9;
              }
              .tr-td {
                width: 50%;
                &:nth-child(1){
                  padding-left: 20px;
                }
              }
            }
          }
        }
      }
    }
  }
}
</style>