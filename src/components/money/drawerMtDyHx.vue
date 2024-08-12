<template>
  <div>
    <!-- 优惠明细表 -->
    <el-drawer
      title="当日卡券核销记录表"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="98%"
    >
      <div class="YH-detail">
        <div class="top" layout="row" layout-align="space-between center">
          <div class="top-left" layout="row" layout-align="start center">
            <el-select v-model="type_id" placeholder="请选择">
              <el-option
                  v-for="item in options"
                  :key="item.value"
                  :label="item.label"
                  :value="item.value">
              </el-option>
            </el-select>
            <input v-model="keyword" placeholder="输入券码模糊搜索" />
            <el-button
                class="m-l-2"
                type="primary"
                style="width:70px;height:30px;line-height:30px;padding:0"
                @click="getTableData"
            >查询</el-button>
            <el-button
                type="info"
                style="width:70px;height:30px;line-height:30px;padding:0"
                @click="resetHandle"
            >重置</el-button>
          </div>
          <el-button
              type="primary"
              @click="exportExcel"
              style="width:90px;height:30px;line-height:30px;padding:0"
          >导出Excel</el-button>
        </div>

        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="start center">
              <div class="th">序号</div>
              <div class="th">操作员</div>
              <div class="th">卡券类型</div>
              <div class="th">卡券金额</div>
              <div class="th">卡券ID</div>
              <div class="th">卡券名称</div>
              <div class="th">卡券券码</div>
              <div class="th">兑换套餐</div>
              <div class="th">状态</div>
              <div class="th">卡台</div>
              <div class="th">开台时间</div>
              <div class="th">订位人</div>
              <div class="th">每台可用张数</div>
              <div class="th">使用模式</div>
              <div class="th">核销时间</div>
              <div class="th">退券时间</div>
              <div class="th">退券人</div>
              <div class="th">操作</div>
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
              <div class="td">{{index + 1}}</div>
              <div class="td">{{item.o}}</div>
              <div class="td">{{item.t}}</div>
              <div class="td">{{(item.a/100).toFixed(2)}}</div>
              <div class="td">{{item.k}}</div>
              <div class="td">{{item.l}}</div>
              <div class="td">{{item.c}}</div>
              <div class="td">{{item.p}}</div>
              <div class="td">{{item.s}}</div>
              <div class="td">{{item.sn}}</div>
              <div class="td">{{item.ot}}</div>
              <div class="td">{{item.se}}</div>
              <div class="td">{{item.uc}}</div>
              <div class="td">{{item.um}}</div>
              <div class="td">{{item.vt}}</div>
              <div class="td">{{item.ct}}</div>
              <div class="td">{{item.ce}}</div>
              <div class="td">
                    <el-button :disabled="item.b === 2"
                      type="info"
                      style="width:50px;height:25px;line-height:25px;padding:0"
                      @click="cancelCoupon(item)">
                      退券
                    </el-button>
              </div>
            </div>
            <p v-if="tableData.length == 0" class="m-t-10 fs14" style="text-align:center">暂无数据</p>
          </div>
        </div>

      </div>

      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_money from "@/api/money";
import mySelect from "@/components/book/select";
import async from "async";
export default {
  data() {
    return {
      options: [{
        value: 0,
        label: '全部'
      },
        {
          value: 12,
          label: '抖音'
        },{
          value: 22,
          label: '美团'
        },{
          value: 32,
          label: '推广'
        }
      ],
      type_id: 0,
      show: false,
      selectInfo: {
        selectVal: "全部",
        selectOption: [],
      },
      keyword: "",
      tableData: [],
    };
  },
  methods: {
    async cancelCoupon(item) {
      await this.$confirm("确定执行退券?", "退券确认", {
        distinguishCancelAndClose: true,
        confirmButtonText: "确定",
        cancelButtonText: "取消",
      }).then(async () =>  {
        try {
          const res = await api_money.cancel_kq_csm({
            kq_order_id: item.id
          });
          console.log('res========', res)
          if (res.code == 1) {
            this.$message.success('退券成功');
            this.getTableData()
          } else {
            this.$message.warning(res.msg);
          }
        } catch (error) {
          console.log("", error);
        }
      }
    )
    },
    // 获取数据
    async getTableData() {
      const params = {
        type_id: this.type_id,
        key: this.keyword,
      }
      try {
        const res = await api_money.get_kq_csm_list_for_back(params);
        if (res.code == 1) {
          this.tableData = (res.data.records || []).map(item => {
            if(item.t * 1 === 12){
              item.t = '抖音券'
            } else if (item.t *1 === 22) {
              item.t = '美团券'
            } else if (item.t * 1 === 32) {
              item.t = '推广券'
            }
            return item
          })
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("表格数据获取失败", error);
      }
    },

    
    resetHandle() {
      this.keyword = "";
      this.type_id = 0;
      this.getTableData();
    },

    // 导出excel
    async exportExcel() {
      const params = {
        type_id: this.type_id,
        key: this.keyword,
      }

      try {
        const res = await api_money.exp_kq_csm_list_for_back(params);
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

    onCancelDrawer() {
      this.$emit("showOrHideMtDyHx");
    },


    
    /*
    筛选下拉框相关 start
    */
    setSelectValHandle(info) {
      this.selectInfo.selectVal = info.name;
    },
    selectBlurHandle() {
      this.selectInfo.selectOption = [];
    },
    getOptionHandle() {
      this.selectInfo.selectOption = JSON.parse(
        JSON.stringify(this.selectInfo.originSelectOption)
      );
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
    showDrawer(newVal) {
      console.log('show kahx drawer', newVal)
      this.show = newVal;
      newVal ? this.resetHandle() : "";
    }
  }
};
</script>

<style scoped lang="less">
@import "../../style/money/drawerMtDyHx";
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementDrawerHeaderAndSession.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";
</style>