<template>
  <!-- 一键分配弹框组件 -->
  <div v-if="showConfirm" class="confirmBg">
    <div class="confirm">
      <div class="title" layout="row" layout-align="space-between center">
        <span>{{title}}</span>
        <i class="el-icon-close" @click="showOrHideConfirm"></i>
      </div>
      <div class="content">
        <!-- 一键分配列表展示 -->
        <div v-if="isAllocation" class="content-allocation">
          <span>有意向卡台的预定信息：</span>
          <!-- 表格数据 -->
          <el-table :data="tableData" height="300" style="width:100%">
            <el-table-column label="序号" width="55">
              <template slot-scope="scope">
                <input :disabled="scope.row.ca==3" style="display:inline-block;vertical-align:middle" type="checkbox"
                  @change="checkoutInput($event,scope.row)" />
                <span style="display:inline-block;vertical-align:middle">{{ scope.row.index }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="orderPersonName" label="订位人" width="80">
            </el-table-column>
            <el-table-column prop="ma" label="最低消费" align="right" width="80">
            </el-table-column>
            <el-table-column prop="cn" label="客人姓名" width="80">
            </el-table-column>
            <el-table-column prop="seatName" label="意向卡台" width="100">
            </el-table-column>
            <el-table-column label="结果" width="130">
              <template slot-scope="scope">
                <span :class="scope.row.ca==3?'red':'green'">{{scope.row.r}}</span>
              </template>
            </el-table-column>
          </el-table>
          <span class="red">说明：有意向卡台且意向卡台为空台，才可以分配卡台</span>
        </div>
        <!-- 一键分配未完全成功结果 -->
        <div v-else-if="!isAllocation&&!customId" class="content-result">
          <p class="m-t-4 m-b-4">
            <span class="red">分配失败：{{allocationResultArr.length}}条</span>&nbsp;&nbsp;&nbsp;
            <span class="green">分配成功：{{selectIdArr.length - allocationResultArr.length}}条</span>
          </p>
          <div class="contain">
            <div class="result" v-for="(item,index) in allocationResultArr" :key="index">
              <div class="result-left red">{{item.t}}</div>
              <div class="result-right">{{item.r}}</div>
            </div>
          </div>
        </div>
        <!-- 客户订单详情 -->
        <div v-else>
          客户历史订单列表
        </div>
      </div>
      <div class="bottom" layout="row" layout-align="end center">
        <button class="cancel" @click="showOrHideConfirm">{{cancelBtnTxt}}</button>
        <button class="primary" v-if="!customId" @click="submitHandle">{{summitBtnTxt}}</button>
      </div>

    </div>
  </div>
</template>

<script>
  import api_reserved from '@/api/Book'
  import common_book from '@/utils/common/book'
  export default {
    data() {
      return {
        isAllocation: true,  // 是否为一键分配操作界面  true：一键分配操作  false：分配后结果
        tableData: [],
        selectIdArr: [],  // 选中的表格id列表
        allocationResultArr: [],  // 一键分配未完全成功结果详情 
      }
    },
    methods: {
      async getTableData(type_id) {
        try {
          const res = await api_reserved.reqGetAllocationList({ type_id })
          if (res.code === 1) {
            if (!res.data) return this.tableData = []
            res.data.forEach((el, index) => {
              el.index = index + 1
              el.seatName = common_book.getOrgionInfo(0, el.s).name + '/' + common_book.getCardInfo(el.s).name
              el.orderPersonName = common_book.getOrderPersonInfo(el.si).name
            })
            this.tableData = res.data
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log('一键分配卡台列表获取失败', error);
        }
      },

      checkoutInput(e, info) {
        const { selectIdArr } = this
        e.target.checked ? selectIdArr.push(info.id) : selectIdArr.splice(selectIdArr.findIndex(el => el === info.id), 1)
        this.selectIdArr = selectIdArr
      },

      submitHandle() {
        if (this.isAllocation) {  // 提交一键分配
          if (this.selectIdArr.length === 0) return this.$message.warning('请选择预定信息')
          this.allocationMany()
        } else { // 返回一键分配
          this.getTableData(this.type_id)
          this.isAllocation = true
          this.allocationResultArr = []
          this.selectIdArr = []
        }
      },

      async allocationMany() {
        try {
          const res = await api_reserved.reqManyAllocation({ book_ids: this.selectIdArr })
          if (res.code === 1) {
            this.$message.success('分配成功')
            this.showOrHideConfirm()
            this.$parent.getTableData()
          } else if (res.code === 2) {  // 一键分配出现失败的清单
            this.isAllocation = false
            this.allocationResultArr = res.data
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log('一键分配卡台失败', error);
        }

      },

      showOrHideConfirm() {
        if (this.showConfirm) this.isAllocation = true
        this.allocationResultArr = []
        this.selectIdArr = []
        this.$emit('showOrHideConfirm')
      }
    },
    created() {

    },
    mounted() {
    },
    props: ['customId', 'showConfirm', 'type_id'],
    computed: {
      title() {
        return this.customId ? '查看历史订单' : (this.isAllocation ? '一键分配' : '分配结果')
      },
      cancelBtnTxt() {
        return this.isAllocation ? '取消' : '关闭'
      },
      summitBtnTxt() {
        return this.isAllocation ? '一键分配' : '返回一键分配'
      }
    },
    watch: {
      showConfirm(newVal) {
        if (newVal) this.getTableData(this.type_id)
      },
      customId(newVal) {
        if (newVal) this.isAllocation = false
      }
    }
  }

</script>

<style scoped lang="less">
  @import '../../../style/book/reserved/operationConfirm.less';
</style>

<style>
  .el-table--border::after,
  .el-table--group::after {
    width: 0;
  }
</style>