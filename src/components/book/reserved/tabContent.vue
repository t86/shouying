<template>
  <div class="contain">
    <!-- 筛选 -->
    <div class="select-box" layout="row" layout-align="start center">
      <div class="date" v-if="!isToday" layout="row" layout-align="center center">
        <span>日期：</span>
        <ul layout="row" layout-align="center center">
          <li :class="{'active':type_id==1}" @click="changeDate(1)">明天</li>
          <li :class="{'active':type_id==2}" @click="changeDate(2)">未来7天</li>
          <li :class="{'active':type_id==3}" @click="changeDate(3)">全部</li>
        </ul>
      </div>
      <input type="text" v-model="keyWord" placeholder="订位人姓名/订位人工号/客户姓名/客户电话">
      <button class="search" @click="searchTableData">查询</button>
      <button class="reset" @click="resetKeyWord">重置</button>
    </div>
    <!-- 操作按钮 -->
    <div class="operate-btn" layout="row" layout-align="start center">
      <button @click="changeShowDrawer">
        <img :src="imgSrc.addIcon" alt="">
        <span>新增预留</span>
      </button>
      <button @click="delReservedInfo">
        <img :src="imgSrc.delIcon" alt="">
        <span>删除预留</span>
      </button>
      <button v-if="isToday" @click="manyAllocationCard">
        <img :src="imgSrc.operateIcon" alt="">
        <span>一键分配卡台</span>
      </button>
    </div>
    <!-- 表格数据 -->
    <div class="table-content">
      <el-table :data="tableData" height="100%" style="width:100%;">
        <el-table-column fixed label="序号" width="55">
          <template slot-scope="scope">
            <input style="display:inline-block;vertical-align:middle" type="checkbox"
              @change="checkoutInput($event,scope.row)" />
            <span style="display:inline-block;vertical-align:middle">{{ scope.row.index }}</span>
          </template>
        </el-table-column>
        <el-table-column fixed prop="departmentName" label="订位人部门" width="100">
        </el-table-column>
        <el-table-column prop="orderPersonName" label="订位人名称" width="140">
        </el-table-column>
        <el-table-column prop="code" label="订位人工号" width="100">
        </el-table-column>
        <el-table-column prop="exp_arrive_time" label="预计到达时间" width="150">
        </el-table-column>
        <el-table-column prop="ma" label="最低消费（元）" align="right" width="120">
        </el-table-column>
        <el-table-column prop="customer_exp_cnt" label="人数" width="80">
        </el-table-column>
        <el-table-column prop="customer_name" label="客人姓名" width="80">
          <template slot-scope="scope">
            <el-link :underline="false" @click="showCusHistoryOrder(scope.row.si)" type="primary">
              {{scope.row.customer_name}}</el-link>
          </template>
        </el-table-column>
        <el-table-column prop="customer_phone" label="客人联系方式" width="120">
        </el-table-column>
        <el-table-column prop="seatName" label="意向卡台" width="120">
        </el-table-column>
        <el-table-column prop="remark" label="备注" width="150">
          <template slot-scope="scope">
            <p :title="scope.row.remark" class="one-txt-cut">{{scope.row.remark}}</p>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="130">
          <template slot-scope="scope">
            <el-link :underline="false" @click.stop="editReservedDate(scope.row)" type="primary">编辑</el-link>
            <el-link :underline="false" @click.stop="allocationCard(scope.row)" v-if="isToday" type="primary">分配卡台
            </el-link>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- drawer -->
    <drawerReserved :showDrawer="drawer.showDrawer" @changeShowDrawer="changeShowDrawer" />
    <!-- 全屏组件---分配卡台 -->
    <fullPageTable @showOrHideFullPageHandle="showOrHideFullPageHandle" titleText="分配卡台"
      :selectedCardInfo="allocationInfo.selectedCardInfo" v-if="allocationInfo.showFullPageTable" />

    <operationConfirm :type_id="this.type_id" :showConfirm="this.confirmInfo.showConfirm" :customId="customId"
      @showOrHideConfirm="showOrHideConfirm" />
  </div>
</template>

<script>
  import api_reserved from '@/api/Book'
  import common_book from '@/utils/common/book'

  import drawerReserved from '@/components/book/reserved/drawerReserved'
  import fullPageTable from '@/components/book/machine/fullPageTable'  // 全屏表格
  import operationConfirm from '@/components/book/reserved/operationConfirm'

  import addIcon from '@/assets/card-imgs/reserved/add.png'
  import delIcon from '@/assets/card-imgs/reserved/delete.png'
  import operateIcon from '@/assets/card-imgs/reserved/operate.png'

  let originTableData = []  // 表格完整数据
  export default {
    data() {
      return {
        keyWord: '',
        type_id: 0, //  0 今天  1 明天 2 未来7天 3 未来全部
        customId: '', // 客人历史订单页面要传入的客人id  用于判断是否为订单详情页和请求数据
        tableData: [],
        selectIdArr: [],  // 选中的表格id列表
        // 分配相关信息
        allocationInfo: {
          id: '', // 当前正在分配的预留订单id
          showFullPageTable: false, // 是否显示选卡台界面
          selectedCardInfo: '',  // 意向卡台info
        },
        imgSrc: {
          addIcon,
          delIcon,
          operateIcon
        },

        drawer: {
          tableRowData: {},
          showDrawer: false
        },

        confirmInfo: {
          showConfirm: false
        }
      }
    },
    methods: {
      // 筛选查询时间
      changeDate(type_id) {
        this.type_id = type_id
        this.getTableData(type_id)
      },

      // 获取表格数据
      async getTableData(type_id = this.type_id, callback) {
        try {
          const res = (this.isToday ? await api_reserved.reqGetCurrentDayList() : await api_reserved.reqGetFutureDayList({ ti: type_id }))
          if (res.code === 1) {
            if (!res.data) return this.tableData = []
            res.data.forEach((el, index) => {
              el.index = index + 1
              el.seatName = common_book.getOrgionInfo(el.exp_region_id, el.exp_seat_id).name + '/' + common_book.getCardInfo(el.exp_seat_id).name
              el.departmentName = common_book.getDepartmentName(el.si)
              el.orderPersonName = common_book.getOrderPersonInfo(el.si).name
              el.code = common_book.getOrderPersonInfo(el.si).code
            })
            if (this.keyWord === '') originTableData = JSON.parse(JSON.stringify(res.data))
            this.tableData = res.data
            // 其它预留文字筛选
            if (!this.isToday || this.keyWord !== '') {
              const { keyWord } = this
              const resultArr = originTableData.filter(el => (el.orderPersonName.startsWith(keyWord) || el.code.toString().startsWith(keyWord) || el.customer_name.startsWith(keyWord) || el.customer_phone.toString().startsWith(keyWord)))
              resultArr.forEach((el, index) => {
                el.index = index + 1
              })
              this.tableData = resultArr
            }
            callback && callback()
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log('表格数据获取失败', error)
        }
      },

      // 批量删除表格数据
      delReservedInfo() {
        if (this.selectIdArr.length === 0) return this.$message.warning('请选择需要删除的列表！')
        this.$confirm('是否确认删除预留信息？', '删除预留', {
          distinguishCancelAndClose: true,
          confirmButtonText: '确定',
          cancelButtonText: '取消'
        }).then(async () => {
          try {
            const res = await api_reserved.reqCancelReservedInfo({ book_ids: this.selectIdArr })
            if (res.code === 1) {
              this.$message.success('删除成功')
              this.selectIdArr = []
              this.getTableData(this.type_id, () => {
                this.$nextTick(() => {
                  const domList = document.querySelectorAll('input[type="checkbox"]')
                  domList.forEach(el => {
                    el.checked = false
                  })
                })
              })
            } else {
              this.$message.warning(res.msg)
            }
          } catch (error) {
            console.log('删除失败', error);
          }
        }).catch(e => '')

      },

      // 关键字搜索筛选表格数据
      searchTableData() {
        const { keyWord } = this
        if (this.isToday) {
          const resultArr = originTableData.filter(el => (el.orderPersonName.startsWith(keyWord) || el.code.toString().startsWith(keyWord) || el.customer_name.startsWith(keyWord) || el.customer_phone.toString().startsWith(keyWord)))
          resultArr.forEach((el, index) => {
            el.index = index + 1
          })
          this.tableData = resultArr
        } else {
          this.getTableData(this.type_id)
        }

      },

      // 重置关键字和表格数据
      resetKeyWord() {
        this.keyWord = ''
        this.tableData = originTableData
      },

      // 勾选或取消表格数据
      checkoutInput(e, info) {
        const { selectIdArr } = this
        e.target.checked ? selectIdArr.push(info.id) : selectIdArr.splice(selectIdArr.findIndex(el => el === info.id), 1)
        this.selectIdArr = selectIdArr
      },

      // 改变drawer状态
      changeShowDrawer() {
        this.drawer.showDrawer = !this.drawer.showDrawer
        this.$children[1].setFomData({})
      },

      // 编辑预留数据信息
      editReservedDate(info) {
        this.changeShowDrawer()
        this.drawer.tableRowData = info
        this.$children[1].setFomData(info)
      },

      // 单个分配卡台页面
      allocationCard(info) {
        this.allocationInfo.id = info.id
        this.allocationInfo.selectedCardInfo = info
        this.allocationInfo.showFullPageTable = !this.allocationInfo.showFullPageTable
      },

      // 显示或隐藏分配卡台组件 
      showOrHideFullPageHandle({ showDrawer, showFullPage, isSubmit }) {
        const newCardInfo = this.$store.state.cardPageInfo.newCardInfo
        if (!isSubmit) this.allocationInfo.showFullPageTable = showFullPage
        const params = {
          id: this.allocationInfo.id,  // int64  待操作预留记录Id
          seat_id: Number(newCardInfo.seatId) || Number(newCardInfo.exp_seat_id) //   int64  待分配卡台Id
        }
        if (isSubmit) this.singleAllocation(params, showFullPage)
      },

      // 分配单个卡台
      async singleAllocation(params, showFullPage) {
        try {
          const res = await await api_reserved.reqSingleAllocation(params)
          if (res.code === 1) {
            this.$store.commit('updateNewCardInfo', {})
            this.$sessionStorage.removeItem('newCardInfo')
            this.$message.success('分配成功')
            this.allocationInfo.showFullPageTable = showFullPage
            this.getTableData(this.type_id)
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log('分配卡台操作失败', error);
        }
      },

      //  一键分配卡台
      manyAllocationCard() {
        this.showOrHideConfirm()
      },

      // 展示或隐藏一键分配模态框 、 历史订单模态框
      showOrHideConfirm() {
        if (this.confirmInfo.showConfirm) this.customId = ''
        this.confirmInfo.showConfirm = !this.confirmInfo.showConfirm
      },

      // 查看客人历史订单
      showCusHistoryOrder(id) {
        this.customId = id.toString()
        this.showOrHideConfirm()
      },

      changeTabHandle(index) {
        if (index == 0) { // 当日
          this.type_id = 0
        } else { // 未来
          this.type_id = 1
        }
        this.getTableData(this.type_id)
      }
    },
    mounted() {
      this.type_id = this.isToday ? 0 : 1
      this.changeTabHandle(this.type_id)
    },
    props: ['isToday'],
    components: {
      drawerReserved,
      fullPageTable,
      operationConfirm
    }
  }

</script>

<style scoped lang="less">
  @import '../../../style/book/reserved/tabContent.less';
  @import '../../../style/common/elementTable.less';
</style>

<style lang="less">
  @import '../../../style/common/elementConfirm.less';
</style>