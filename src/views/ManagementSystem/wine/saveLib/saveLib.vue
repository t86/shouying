<template>
  <!-- 存酒库 -->
  <div class="save-lib">
    <div class="top">
      <div class="item m-b-2" layout="row" layout-align="start center">
        <div class="label fs14">存酒日期：</div>
        <div class="value">
          <el-date-picker
            style="width:140px"
            v-model="start_bef_in_day"
            type="date"
            :clearable="false"
            size="small"
            value-format="yyyy-MM-dd"
            placeholder="开始日期"
          ></el-date-picker>
          <span>至</span>
          <el-date-picker
            style="width:140px"
            v-model="end_bef_in_day"
            type="date"
            :clearable="false"
            size="small"
            value-format="yyyy-MM-dd"
            placeholder="结束日期"
          ></el-date-picker>
        </div>

        <div class="label fs14 m-l-6">剩余过期时间：</div>
        <div class="value fs14">
          <el-input v-model="dayVal" style="width:60px" class="m-r-2" size="small" placeholder="天数"></el-input>天
        </div>
      </div>
      <el-input
        v-model="keyword"
        style="width:360px"
        class="m-r-2"
        size="small"
        placeholder="输入客人姓名/手机号码/商品/卡台/存酒流水号/订位人"
      ></el-input>
      <el-button type="primary" size="small" @click="getTableData">查询</el-button>
      <el-button size="small" @click="resetHandle">重置</el-button>
    </div>
    <div class="btn-area m-t-4 m-b-2">
      <el-button type="primary" size="small" @click="showLongDrawerHandle">延期</el-button>
      <el-button type="primary" size="small" @click="batchToStore">批量充公</el-button>
      <el-button type="primary" size="small" @click="exportDetailHandle">明细导出</el-button>
    </div>
    <span class="color-red">说明：充公酒水将进入待充公列表</span>
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
            <div class="th">入库时间</div>
            <div class="th">入库人</div>
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
              <div class="td">{{item.it}}</div>
              <div class="td">{{item.we}}</div>
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
                <div class="tr-th">过期时间</div>
                <div class="tr-th">延期次数</div>
                <div class="tr-th">累计延期天数</div>
                <div class="tr-th">授权人</div>
                <div class="tr-th">备注手机号</div>
                <div class="tr-th">备注姓名</div>
                <div class="tr-th">存酒流水号</div>
              </div>
              <div class="tr-tbody">
                <div
                  class="tr-tr"
                  layout="row"
                  layout-align="space-between center"
                  v-for="(items, i) in (item.ss || [])"
                  :key="items.id"
                  :class="{red: items.isShortTime}"
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
                  <div class="tr-td">{{items.e}}</div>
                  <div class="tr-td">{{items.dc}}</div>
                  <div class="tr-td">{{items.dd}}</div>
                  <div class="tr-td">{{items.a}}</div>
                  <div class="tr-td">{{items.rp}}</div>
                  <div class="tr-td">{{items.rn}}</div>
                  <div class="tr-td" style="user-select: text;">{{items.id}}</div>
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

    <drawerLongTime v-model="showLongDrawer" :ids="ids" @getTableData="getTableData" />

    
    <el-dialog
      title="批量充公"
      @close="toStoreDialog = false"
      :visible.sync="toStoreDialog"
      :close-on-click-modal="false"
    >
      <div style="height: 60px; padding-top: 30px; ">
        <span>请确认是否将所选酒水批量充公？</span>
      </div>
      <span slot="footer" class="dialog-footer">
        <el-button @click="toStoreDialog = false">取消</el-button>
        <el-button type="primary" @click="toStoreHandle">确认</el-button>
      </span>
    </el-dialog>
  </div>
</template>
 
<script>
import { keyHandle } from "../../../../mixin/keyhandle";
import api_wine from "@/api/wine";
import drawerLongTime from './drawerLongTime.vue'
export default {
  data() {
    return {
      ids: [],
      start_bef_in_day: "", // 存酒开始日期
      end_bef_in_day: "", // 存酒结束日期
      dayVal: "", // 剩余多少天
      keyword: "",
      tableData: [],
      showLongDrawer: false,  // 延期drawer
      toStoreDialog: false,
      allChecked: false,
      isIndeterminate: false,
    };
  },
  methods: {
    async getTableData() {
      const params = {
        start_bef_in_day: this.start_bef_in_day, //  string  开始日期,格式 yyyy-mm-dd
        end_bef_in_day: this.end_bef_in_day, // string  结束日期,格式 yyyy-mm-dd
        expired_day: this.dayVal * 1, // int   多少天内过期
        key: this.keyword || "" //  string     //Key 搜索关键字
      };

      try {
        const res = await api_wine.reqGetSaveLibList(params);
        if (res.code == 1) {
          res.data.records = res.data.records || [];

          const oneDay = +new Date('2023/05/19 12:00') - +new Date('2023/05/18 12:00')
          const sevenDayAgo = 7 * oneDay + +new Date()
          res.data.records.forEach(el => {
            el.ss = (el.ss || []).map(item => ({
              ...item,
              checked: false,
              isShortTime: +new Date(item.e) - sevenDayAgo <= 0
            }));
            el.show = true
            el.checkAll = false;
            el.isIndeterminate = false
          });

          this.tableData = res.data.records;
          this.ids = []
          this.allChecked = false
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("存酒库列表数据获取失败", error);
      }
    },

    showLongDrawerHandle(){
      if(this.ids.length <=0) return this.$message.warning('请选择需要延期的商品')
      this.showLongDrawer = true
    },

    batchToStore(){
      if(this.ids.length <=0) return this.$message.warning('请选择需要充公的商品')
      this.toStoreDialog = true
    },
    async toStoreHandle(){
      const params = {
        invt_ids: this.ids, //    []int64    库存Id列表
      };

      try {
        const res = await api_wine.reqCgWineInvt(params);
        if(res.code == 1) {
          this.$message.success('已加入待充公列表')
          this.getTableData();
          this.toStoreDialog = false;
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("库存充公失败", error);
      }
    },
    async exportDetailHandle(){
      try {
        const params = {
        start_bef_in_day: this.start_bef_in_day, //  string  开始日期,格式 yyyy-mm-dd
        end_bef_in_day: this.end_bef_in_day, // string  结束日期,格式 yyyy-mm-dd
        expired_day: this.dayVal * 1, // int   多少天内过期
        key: this.keyword || "" //  string     //Key 搜索关键字
      };
        const res = await api_wine.reqExportWineDetailList(params);
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
      // this.ids = itemInfo.ss.filter(item => item.checked).map(item => item.id * 1);
      itemInfo.isIndeterminate = !itemInfo.checkAll && itemInfo.ss.some(item => item.checked);
      const ids = []
      let checkedAll = true;
      this.tableData.forEach(el => {
        el.ss.forEach(ele => {
          if(ele.checked) ids.push(ele.id)
          else checkedAll = false;
        })
      })
      this.ids = ids
      this.allChecked = checkedAll
      this.isIndeterminate = !checkedAll && ids.length > 0
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
    resetHandle(){
      const oneHour = +new Date('2023/07/22 12:00:00') - +new Date('2023/07/22 11:00:00')
      const date = new Date(+new Date() - 8 * oneHour)
      const year = date.getFullYear()
      const month = (date.getMonth() + 1).toString().padStart(2, 0)
      const day = date.getDate().toString().padStart(2, 0)
      const now = year + '-' + month + '-' + day
      this.start_bef_in_day = now
      this.end_bef_in_day = now
      this.dayVal = ""
      this.keyword = ""
      this.checkAll = false
      this.getTableData()
    },
  },
  mixins: [keyHandle],
  created() {
    this.resetHandle();
  },
  components: {
    drawerLongTime
  },
};
</script>

<style lang="less" scoped>
@import "../../../../style/wine/table.less";
</style>
<style scoped lang="less">
.save-lib {
  padding: 20px;
  .table-content {
    .table {
      .thead .th {
        font-size: 15px;
      }
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
          font-size: 13px;
          .tr-thead {
            height: 30px;
            width: 100%;
            background-color: #eee;
            .tr-th {
              width: 50%;
              color: #6A6A74;
              font-weight: 600;
              &:nth-child(1){
                padding-left: 20px;
                /deep/.el-checkbox__label{
                  font-weight: 600;
                  color: #6A6A74;
                }
              }
              &:nth-child(1),
              &:nth-child(3),
              &:nth-child(4),
              &:nth-child(5),
              &:nth-child(7),
              &:nth-child(9){
                width: 30%;
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
              &.red{
                color: red;
              }
              .tr-td {
                width: 50%;
                &:nth-child(1){
                  padding-left: 20px;
                }
                &:nth-child(1),
                &:nth-child(3),
                &:nth-child(4),
                &:nth-child(5),
                &:nth-child(7),
                &:nth-child(9){
                  width: 30%;
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

<style>
/* 日期选择器 */
.el-date-picker__header-label {
  color: #1a1a21;
}
.el-date-table th,
.el-picker-panel__content {
  color: #1a1a21;
}
.el-range-editor--small .el-range-input {
  background-color: transparent;
}
</style>