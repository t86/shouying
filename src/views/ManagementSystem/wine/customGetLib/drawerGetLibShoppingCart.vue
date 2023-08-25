<template>
  <div>
    <!-- 待取酒列表 -->
    <el-drawer
      title="待取酒列表"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="90%"
    >
      <div class="session p-5">
        <div class="table-content">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">酒水名称</div>
                <div class="th">规格</div>
                <div class="th">每瓶克数</div>
                <div class="th">库存数量</div>
                <div class="th">取酒数量</div>
                <div class="th">过期时间</div>
                <div class="th">备注姓名</div>
                <div class="th">备注手机号</div>
                <div class="th">存酒流水号</div>
                <div class="th">操作</div>
              </div>
            </div>
            <div class="tbody">
              <div
                class="tr"
                layout="row"
                layout-align="space-between center"
                v-for="item in tableData"
                :key="item.id"
              >
                <div class="td">{{item.n}}</div>
                <div class="td">{{item.u}}</div>
                <div class="td">{{item.g || '-'}}</div>
                <div class="td">{{item.c}}</div>
                <div class="td" layout="row" layout-align="center center">
                  <el-button
                    type
                    size="small"
                    style="width:26px;padding:0;height:26px;border-radius:50%"
                    icon="el-icon-minus"
                    :disabled="item.count<=1"
                    @click="item.count = Math.max(1, item.count - 1)"
                  ></el-button>
                  <el-input v-model="item.count" @input="changeCount(item.count, item)" size="mini" style="width:60px;margin:0 10px"></el-input>
                  <el-button
                    type
                    size="mini"
                    :disabled="item.count >= item.c"
                    style="width:26px;padding:0;height:26px;border-radius:50%"
                    icon="el-icon-plus"
                    @click="item.count++"
                  ></el-button>
                </div>
                <div class="td">{{item.e}}</div>
                <div class="td">{{item.rn}}</div>
                <div class="td">{{item.rp}}</div>
                <div class="td" style="user-select: text;">{{item.id}}</div>
                <div class="td"><span style="color:#2170ff;cursor:pointer" @click="deleteHandle(item)">删除</span></div>
              </div>
            </div>
            <div class="no-data" v-if="tableData.length==0">
              <img src="@/assets/img/wu.png" alt />
              <p>暂无数据</p>
            </div>
          </div>
        </div>

        <drawerChooseSeat v-model="showChooseSeatDrawer" @submitHandle="submitSureHandle"/>

        <el-dialog
          title="提示"
          :visible.sync="dialogVisible"
          append-to-body
          width="30%">
          <p>确认出库吗？</p>
          <span slot="footer" class="dialog-footer">
            <el-button @click="dialogVisible = false">取 消</el-button>
            <el-button type="primary" @click="submitHandle">确 定</el-button>
          </span>
        </el-dialog>

      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="primary" @click="clearShoppingCartHandle">清空列表</el-button>
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" @click="onSubmit">下一步</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_wine from '@/api/wine'
import drawerChooseSeat from './drawerChooseSeat.vue'
export default {
  data() {
    return {
      dialogVisible: false,
      showChooseSeatDrawer: false,
      tableData: [],
      seatInfo: {}
    };
  },
  methods: {
    // 改变取酒数量
    changeCount(count, itemInfo){
      if(isNaN(count * 1)){
        this.$message.warning('请输入数字')
      }
      if(count > itemInfo.c) itemInfo.count = itemInfo.c

      if(count <= 0) itemInfo.count = 1
    },
    // 删除
    deleteHandle(itemInfo){
      const index = this.tableData.findIndex(item => item.id == itemInfo.id)
      if(index > -1) {
        this.tableData.splice(index, 1)
        this.$emit('shoppingCartComChangeShoppingCartListHandle', this.tableData)
      }
    },
    // 清空列表
    clearShoppingCartHandle(){
      this.tableData = []
      this.$emit('shoppingCartComChangeShoppingCartListHandle', this.tableData)
    },

    onSubmit (){
      if(this.tableData.length <= 0) return this.$message.warning('请选择取酒订单')
      this.showChooseSeatDrawer = true  
    },

    async submitHandle(){
      const params = {
        seat_id: this.seatInfo.id * 1, //    int64   取酒目标卡台Id
        invt_ids: this.tableData.map(item => item.id * 1), //   []int64   取酒库存Id列表
        prd_cnts: this.tableData.map(item => item.count * 1), //   []int   对应上面库存Id的取酒商品数量
      }
      try {
        const res = await api_wine.reqGetCustomCenterGetWineSubmit(params)
        if(res.code == 1) {
          this.$message.success('取酒成功')
          this.showChooseSeatDrawer = false
          this.onCancelDrawer()
          this.$emit('getTableData', true)
        } else {
          this.$message.warning(res.msg)
        }
        this.dialogVisible = false
      } catch (error) {
        console.log('取酒失败', error)
      }
    },

    submitSureHandle(seatInfo){
      this.seatInfo = seatInfo
      this.dialogVisible = true
    },

    onCancelDrawer(){
      this.show = false
    },

  },
  mounted() {},
  props: {
    value: {
      default: false // 是否显示drawer
    },
    shoppingCartList: {
      default: () => ([])
    }
  },
  computed: {

    show: {
      get(){
        return this.value
      },

      set(val) {
        this.$emit('input', val)
      }
    }
  },
  components: {
    drawerChooseSeat
  },
  watch: {
    value: {
      handler(newVal) {
        if(newVal) {
          this.tableData = this.shoppingCartList.map(item => ({
            ...item,
            count: item.c
            }))
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import '../../../../style/common/elementDrawerWine.less';
@import '../../../../style/common/elementDrawerHeaderAndSession.less';
@import '../../../../style/common/elementFormBtnWine.less';
@import "../../../../style/wine/table.less";
</style>

<style lang="less" scoped>
  .table-content {
    width: 100%;
    overflow: auto;
    .table {
      min-width: 1300px;
      height: calc(100vh - 170px);
      .thead {
        z-index: 9;
        .th {
          background-color: #eee;
        }
      }

      .tbody {
        .tr {
          &:nth-child(2n) {
            .td:nth-child(1),
            .td:nth-child(2){
              background-color: #f5f5f5;
            }
          }
          &:nth-child(2n + 1) {
            .td:nth-child(1),
            .td:nth-child(2){
              background-color: #fff;
            }
          }
        }
      }
      .th,.td {
        padding: 0 6px;
        height: 30px;
        line-height: 30px;
        box-sizing: border-box;
        &:nth-child(2),
        &:nth-child(3),
        &:nth-child(4),
        &:nth-child(10){
          width: 30%;
        }

        &:nth-child(1){
          position: sticky;
          left: 0;
          z-index: 9;
        }
        &:nth-child(2){
          position: sticky;
          left: 153px;
          z-index: 9;
        }
      }
    }
  }
  
/deep/.el-button--default {
  background-color: #fff;
}
</style>