<template>
  <div class="table-detail">
    <div class="group">
      <h3 class="fs18 m-b-2">下级部门</h3>
      <div class="top" layout="row" layout-align="start center">
        <icon-button @click.native="addOrUpdateHandle(11)" text="新增" img="btn_add.png" colors="#383943"></icon-button>
        <icon-button @click.native="addOrUpdateHandle(12)" text="编辑" img="btn_edit.png" colors="#383943"></icon-button>
        <icon-button @click.native="setEffectOrNotEffect(11)" text="置为无效" img="btn_in_vain.png" colors="#383943"></icon-button>
        <icon-button @click.native="setEffectOrNotEffect(12)" text="置为有效" img="btn_effective.png" colors="#383943"></icon-button>
        <icon-button @click.native="setEffectOrNotEffect(13)" text="批量删除" img="btn_delete.png" colors="#6B2830"></icon-button>
      </div>
      <div class="table-content table1">
        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="start center">
              <div class="th">
                <el-checkbox
                  v-model="groupCheckAll"
                  :indeterminate="isIndeterminate"
                  @change="changeCheckboxHandle('groupAll')"
                >全选</el-checkbox>
              </div>
              <div class="th">部门名称</div>
              <div class="th">人员数量</div>
              <div class="th">状态</div>
              <div class="th">更新时间</div>
              <div class="th">更新时间</div>
            </div>
          </div>
          <div class="tbody">
            <div
              class="tr"
              v-for="(item,index) in groupTableData"
              :key="index"
              layout="row"
              layout-align="start center"
              :class="{'selected': item.checked,'gray': item.s == '无效'}"
            >
              <div class="td">
                <el-checkbox
                  v-model="item.checked"
                  @change="changeCheckboxHandle('groupItem')"
                >{{index + 1}}</el-checkbox>
              </div>
              <div class="td">{{item.n}}</div>
              <div class="td">{{item.ec}}</div>
              <div class="td">{{item.s}}</div>
              <div class="td">{{item.c}}</div>
              <div class="td">{{item.u}}</div>
            </div>
            <div class="no-data" v-if="groupTableData.length==0">
              <img src="@/assets/img/wu.png" alt />
              <p>暂无数据</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="employee m-t-6">
      <h3 class="fs18 m-b-2">部门员工</h3>
      <div class="top" layout="row" layout-align="start center">
        <icon-button @click.native="addOrUpdateHandle(21)" text="新增" img="btn_add.png" colors="#383943"></icon-button>
        <icon-button @click.native="addOrUpdateHandle(22)" text="编辑" img="btn_edit.png" colors="#383943"></icon-button>
        <icon-button @click.native="setEffectOrNotEffect(21)" text="置为无效" img="btn_in_vain.png" colors="#383943"></icon-button>
        <icon-button @click.native="setEffectOrNotEffect(22)" text="置为有效" img="btn_effective.png" colors="#383943"></icon-button>
        <icon-button @click.native="setEffectOrNotEffect(23)" text="批量删除" img="btn_delete.png" colors="#6B2830"></icon-button>
        <characters-button @click.native="anotherEffectHandle(1)" colors="#383943" wz='批量修改部门'></characters-button>
        <characters-button @click.native="anotherEffectHandle(2)" colors="#383943" wz='批量修改直属上级'></characters-button>
        <characters-button @click.native="anotherEffectHandle(3)" colors="#383943" wz='批量导入'></characters-button>
        <characters-button @click.native="anotherEffectHandle(4)" colors="#383943" wz='批量重置密码'></characters-button>
      </div>
      <div class="table-content table2">
        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="start center">
              <div class="th">
                <el-checkbox
                  v-model="empCheckAll"
                  :indeterminate="empIsIndeterminate"
                  @change="changeCheckboxHandle('empAll')"
                >全选</el-checkbox>
              </div>
              <div class="th">姓名</div>
              <div class="th">岗位</div>
              <div class="th">工号</div>
              <div class="th">性别</div>
              <div class="th">状态</div>
              <div class="th">联系方式</div>
              <div class="th">简写</div>
              <div class="th">创建时间</div>
              <div class="th">操作</div>
            </div>
          </div>
          <div class="tbody">
            <div
              class="tr"
              v-for="(item,index) in employeeTableData"
              :key="index"
              layout="row"
              layout-align="start center"
              :class="{'selected': item.checked,'gray': item.s == '无效'}"
            >
              <div class="td">
                <el-checkbox
                  v-model="item.checked"
                  @change="changeCheckboxHandle('empItem')"
                >{{index + 1}}</el-checkbox>
              </div>
              <div class="td">{{item.n}}</div>
              <div class="td">{{item.sn}}</div>
              <div class="td">{{item.cd}}</div>
              <div class="td">{{item.sx}}</div>
              <div class="td">{{item.s}}</div>
              <div class="td">{{item.pn}}</div>
              <div class="td">{{item.np}}</div>
              <div class="td">{{item.c}}</div>
              <div class="td">
                <span class="primary-link cursor" @click="showOrHideBindHandle(item)">{{item.bs == '未绑定'?'绑定员工': item.bs=='已绑定' ? '解除绑定' : '解绑中'}}</span>
                <span class="primary-link cursor" @click="makeCardHandle(item)">{{item.wc == 1 ? '清卡': '制卡'}}</span>
                <span class="primary-link cursor" v-if="item.wc==1" @click="destoryCard(item)">作废卡</span>
              </div>
            </div>
            <div class="no-data" v-if="employeeTableData.length==0">
              <img src="@/assets/img/wu.png" alt />
              <p>暂无数据</p>
            </div>
          </div>
        </div>
      </div>
      <div class="pagination m-t-2">
        <el-pagination
          background
          layout="prev, pager, next"
          :total="pageInfoEmp.pageTotal"
          :page-size="pageInfoEmp.pageSize"
          :current-page="pageInfoEmp.page"
          @current-change="changePageHandle"
        ></el-pagination>
      </div>

      <!-- 新增或修改部门/员工 -->
      <drawerAddOrUpdate 
        v-model="showAddOrUpdateDrawer" 
        :menuList="menuList" 
        :menuId="$route.query.menuId" 
        :type="type" 
        :currentInfo="currentInfo"
        @getMenuList="$emit('getMenuList')"
        @getTableData="getTableData"
         />

      <!-- 置为有效无效删除冲突部门/员工 -->
      <drawerNextDrawer 
        v-model="showNextDrawer" 
        :effectType="effectType" 
        :nexDrawerInfo="nexDrawerInfo"  
        @getMenuList="$emit('getMenuList')"
        @getTableData="getTableData" 
        @setEffectOrNotEffect="setEffectOrNotEffect"
        />


        <!-- 员工批量修改部门  批量修改直属上级  批量修改密码 -->
        <drawerEmpOther 
          v-model="showOtherDrawer"
          :otherType="otherType"
          :checkedList="checkedList"
          @getTableData="getTableData" 
        />

        <!-- 批量导入员工 -->
        <drawerImportEmp 
          v-model="showImportDrawer" 
          @getTableData="getTableData"
          @getMenuList="$emit('getMenuList')" 
        />

        <!-- 绑定员工 -->
        <drawerBindEmp 
          v-model="showBindEmpDrawer"
          :currentBindPersonInfo="currentBindPersonInfo"
          @getEmpTableList="getEmpTableList"
        />

        
        <!-- 制卡/清卡操作模态框 -->
        <div layout="row" style="width:100vw;height:100vw;background:rgba(0,0,0,.3);position:fixed;left:0;top:0;z-index:999" @keyup.esc="showMakeCardModal=false" v-if="showMakeCardModal">
          <div style="padding:30px 20px;width:400px;background:#fefefe;position:absolute;top:40vh;left:50%;transform:translate(-50%,-50%);border-radius:10px">
            <p style="line-height:100px;text-align:center;font-size:20px">请将卡片放置于读卡器感应区</p>
            <div style="width:80px;height:36px;margin:20px auto 0;line-height:36px;border-radius:8px;background:#ccc;text-align:center;cursor:pointer" @click="showMakeCardModal=false">取消操作</div>
          </div>
        </div>
    </div>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      type: 1,  // 11：新增部门  12：编辑部门   21：新增员工   22：编辑员工  
      groupCheckAll: false,
      groupTableData: [],
      pageInfoEmp: {
        page: 1,
        pageSize: 20,
        pageTotal: 0
      },
      empCheckAll: false,
      employeeTableData: [],

      showAddOrUpdateDrawer: false, // 显示或隐藏新增或修改部门/员工
      currentInfo: {}, // 修改部门/员工的选中信息

      showNextDrawer: false, // 有效无效删除冲突时的下一步操作drawer
      effectType: 11, // 11/21 无效  12/22 有效  13/23 删除
      nexDrawerInfo: {
        ns: [],
        cs: []
      },

      showOtherDrawer: false,
      otherType: 1, // 1：批量修改部门  2：批量修改直属上级  3：批量导入  4：批量重置密码
      checkedList: [], // 操作前选中的员工信息

      showImportDrawer: false, // 批量导入

      showBindEmpDrawer: false, // 绑定员工
      currentBindPersonInfo: {}, // 当前绑定的员工信息

      showMakeCardModal: false, // 制卡/清卡操作模态框
    };
  },
  methods: {
    getTableData(){
      this.getGroupTableList()
      this.getEmpTableList()
    },
    async getGroupTableList() {
      const params = {
        id: this.$route.query.menuId * 1
      };

      try {
        const res = await this.$api.BMS.dept.requestdeptlist(params)
        if(res.code == 1) {
          this.groupTableData = (res.data || []).map(item => ({
            ...item,
            checked: false
          }))
          this.groupCheckAll = false
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("卡台列表获取失败", error);
      }
    },

    async getEmpTableList() {
      const params = {
        page_num: this.pageInfoEmp.page * 1,
        page_size: this.pageInfoEmp.pageSize,
        dept_id: this.$route.query.menuId * 1
      };
      if(!params.dept_id) {
        this.employeeTableData = []
        this.pageInfoEmp.page = 1
        this.pageInfoEmp.pageTotal = 0  
        return 
      }
      try {
        const res = await this.$api.BMS.emp.requestEmpList(params)
        if(res.code == 1) {
          this.employeeTableData = (res.data.emps || []).map(item => ({
            ...item,
            checked: false
          }))
          this.empCheckAll = false
          this.pageInfoEmp.pageTotal = res.data.row_cnt || 0
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("卡台列表获取失败", error);
      }
    },

    addOrUpdateHandle(type){
      this.type = type
      switch (type) {
        case 11: // 新增部门
        case 12: // 编辑部门
        case 21: // 新增员工
        case 22: // 编辑员工
          if(type == 12 || type == 22) {
            const api = type == 12 ? 'groupTableData' : 'employeeTableData'
            const checkedList = this[api].filter(item => item.checked)
            if(checkedList.length != 1) return this.$message.warning('请选择一个进行编辑')
            this.currentInfo = {...checkedList[0]}
          } else if(type == 21) {
            // 新建员工
            if(!this.$route.query.menuId) {
              return this.$message.warning('请选择部门')
            }
          }
          this.showAddOrUpdateDrawer = true
          break;
      }
    },

    // 部门/员工设置有效无效删除
    async setEffectOrNotEffect(type){
      let checkedList = []
      let params = {}
      switch (type) {
        case 11: // 无效部门
        case 12: // 有效部门
        case 13: // 删除部门
          this.effectType = type
          checkedList = this.groupTableData.filter(item => item.checked)
          if(checkedList.length <= 0) return this.$message.warning('请选择后进行操作')
          params = {
            ids: checkedList.map(item => item.id * 1)
          }
          try {
            const api = type == 11 ? 'requestdeptDisable' : (type == 12 ? 'requestdeptEnable' : 'requestdeptDel')
            const res = await this.$api.BMS.dept[api](params)
            if(res.code == 1) {
              this.getTableData()
              this.$message.success('操作成功')
            } else if(res.code == 2) {
              this.showNextDrawer = true
              this.nexDrawerInfo.ns = res.data.ns || []
              this.nexDrawerInfo.cs = (res.data.cs || []).map(item => ({
                ...item,
                jg: '---'
              }))
            } else {
              this.$message.warning(res.msg)
            }
          } catch (error) {
            console.log('设置有效无效失败', error);
          }
          this.$emit('getMenuList')
          break
        case 21: // 无效员工
        case 22: // 有效员工
        case 23: // 删除员工
          this.effectType = type
          checkedList = this.employeeTableData.filter(item => item.checked)
          if(checkedList.length <= 0) return this.$message.warning('请选择后进行操作')
          params = {
            ids: checkedList.map(item => item.id * 1)
          }
          try {
            const api = type == 21 ? 'requestEmpDisable' : (type == 22 ? 'requestEmpEnable' : 'requestEmpDel')
            const res = await this.$api.BMS.emp[api](params)
            if(res.code == 1) {
              this.getTableData()
              this.$message.success('操作成功')
            } else if(res.code == 2) {
              this.showNextDrawer = true
              this.nexDrawerInfo.ns = res.data.ns || []
              this.nexDrawerInfo.cs = (res.data.cs || []).map(item => ({
                ...item,
                jg: '---'
              }))
            } else {
              this.$message.warning(res.msg)
            }
          } catch (error) {
            console.log('设置有效无效失败', error);
          }
          break;
      }
    },

    // 其他操作
    anotherEffectHandle(type) {
      // type: 1：批量修改部门  2：批量修改直属上级  3：批量导入  4：批量重置密码
      if(type == 3) {
        this.showImportDrawer = true
      } else {
        const checkedList = this.employeeTableData.filter(item => item.checked)
        if(checkedList.length <= 0) return this.$message.warning('请选择需要操作的员工')
        this.checkedList = [...checkedList]
        this.otherType = type
        this.showOtherDrawer = true
      }
    },

    changeCheckboxHandle(type) {
      switch (type) {
        case "groupAll":
          this.groupTableData = this.groupTableData.map(item => ({
            ...item,
            checked: this.groupCheckAll
          }));
          break;
        case "groupItem":
          this.groupCheckAll = this.groupTableData.every(item => item.checked);
          break;
        case "empAll":
          this.employeeTableData = this.employeeTableData.map(item => ({
            ...item,
            checked: this.empCheckAll
          }));
          break;
        case "empItem":
          this.empCheckAll = this.employeeTableData.every(item => item.checked);
          break;
      }
    },

    // 显示或隐藏绑定员工的drawer
    showOrHideBindHandle(itemInfo = {}){
      if(itemInfo && itemInfo.bs == '解绑中' && !this.showBindEmpDrawer) return this.$message.warning('解绑中，请勿操作')
      this.showBindEmpDrawer = !this.showBindEmpDrawer
      this.currentBindPersonInfo = {...itemInfo}
      if(!this.showBindEmpDrawer) this.getEmpTableList();
    },


    
    /**
     * 制卡
     */

    makeCardHandle(itemInfo){
      try {
        const termType = atool.getTermType();
        if(termType == 'pc') {
          this.showMakeCardModal = true
          this.readCard(itemInfo)
        } else {
          this.$message.warning('当前设备不支持制卡')
        }
      } catch (error) {
        this.$message.warning('当前设备不支持该功能')
      }
    },

    // 读取卡号
    readCard(itemInfo) {
      let cardNo = ''
      try {
        setTimeout(() => {
          cardNo = atool.getCardNo();
          if(!cardNo) {
            if(this.showMakeCardModal) this.readCard(itemInfo)
          } else {
            itemInfo.wc == 1 ? this.getClearCardInfo(cardNo, itemInfo) : this.getBeginCardInfo(cardNo, itemInfo)
          }
        }, 1000);
      } catch (error) {
        console.log('cardNo信息获取失败：', error)
      }
    },
    // 开始制卡
    async getBeginCardInfo(cardNo, itemInfo){
      const params = {
        card_no: cardNo, //    string   卡号
        emp_id: itemInfo.id * 1, //     int64    关联员工
      }
      try {
        const res = await this.$api.BMS.emp.reqBeginMakeCard(params)
        if(res.code == 1) {
          try {
            const result = atool.doRegCard(res.data.card_pass, res.data.card_verify_data)
            if(result === '0') {
              this.makeCardEnd(cardNo, itemInfo)
            } else {
              this.$message.warning('制卡失败')
              this.showMakeCardModal = false
            }
          } catch (e) {
            this.showMakeCardModal = false
            console.log('制卡失败', e)
          }
        } else {
          this.showMakeCardModal = false
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('制卡begin失败', error)
      }
    },

    // 结束制卡
    async makeCardEnd(cardNo, itemInfo) {
      const params = {
        card_no: cardNo, //    string  卡号
        emp_id: itemInfo.id * 1, //     int64   关联员工
      }
      try {
        const res = await this.$api.BMS.emp.reqEndMakeCard(params)
        if(res.code == 1) {
          this.$message.success('制卡成功')
          this.showMakeCardModal = false
          this.getEmpTableList(); 
        } else {
          this.showMakeCardModal = false
          this.$message.warning(res.msg)
        }
      } catch (error) {
        this.showMakeCardModal = false
        console.log('制卡结束失败', error)
      }
    },

    // 开始清卡
    async getClearCardInfo(cardNo, itemInfo){
      const params = {
        emp_id: itemInfo.id * 1, //     int64    关联员工
      }
      try {
        const res = await this.$api.BMS.emp.reqBeginClearCard(params)
        if(res.code == 1) {
          if(res.data.card_no != cardNo) return this.$message.warning('当前员工的绑定卡与当前所刷的卡不一致')
          try {
            const result = atool.doClearCard(res.data.card_pass)
            if(result === '0') {
              this.clearCardEnd(cardNo, itemInfo)
            } else {
              this.$message.warning('清卡失败')
              this.showMakeCardModal = false
            }
          } catch (e) {
            this.showMakeCardModal = false
            console.log('清卡失败', e)
          }
        } else {
          this.showMakeCardModal = false
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('清卡begin失败', error)
      }
    },

    // 结束清卡
    async clearCardEnd(cardNo, itemInfo) {
      const params = {
        card_no: cardNo, //    string  卡号
        emp_id: itemInfo.id * 1, //     int64   关联员工
      }
      try {
        const res = await this.$api.BMS.emp.reqEndClearCard(params)
        if(res.code == 1) {
          this.$message.success('清卡成功')
          this.showMakeCardModal = false
          this.demand(); 
        } else {
          this.showMakeCardModal = false
          this.$message.warning(res.msg)
        }
      } catch (error) {
        this.showMakeCardModal = false
        console.log('清卡end失败', error)
      }
    },

    // 作废卡
    async destoryCard(itemInfo){
      const params = {
        emp_id: itemInfo.id * 1  //   int64  员工Id
      }

      try {
        const res = await this.$api.BMS.emp.reqDestoryCard(params)
        if(res.code == 1) {
          this.$message.success('作废卡成功')
          this.getEmpTableList(); 
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('作废失败', error)
      }
    },

    changePageHandle(page) {
      this.pageInfoEmp.page = page
      this.getEmpTableList()
    }
  },

  props:{
    menuList: {
      default: () => ([])
    }
  },

  computed: {
    isIndeterminate() {
      return !this.groupCheckAll && this.groupTableData.some(item => item.checked);
    },
    empIsIndeterminate() {
      return !this.empCheckAll && this.employeeTableData.some(item => item.checked);
    }
  },

  components: {
    IconButton: () => import('@/components/IconButton.vue'),
    CharactersButton: () => import('@/components/CharactersButton.vue'),
    drawerAddOrUpdate: () => import('./drawerCom/drawerAddOrUpdate.vue'),
    drawerNextDrawer: () => import('./drawerCom/drawerNextDrawer.vue'),
    drawerEmpOther: () => import('./drawerCom/drawerEmpOther.vue'),
    drawerImportEmp: () => import('./drawerCom/drawerImportEmp.vue'),
    drawerBindEmp: () => import('./drawerCom/drawerBindEmp.vue'),
  },


  watch: {
    $route(newVal) {
      this.pageInfoEmp.page = 1
      this.getTableData()
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../../../style/erp/table.less";
</style>
<style lang="less" scoped>
.top {
  background-color: #eee;
}

.table-content {
  width: 100%;
  overflow: auto;
  &.table1 {
    height: calc(50vh - 260px);
    .th,.td {
      &:nth-child(1),
      &:nth-child(3),
      &:nth-child(4){
        width: 40%;
      }
    }
  }
  &.table2 {
    height: calc(50vh - 90px);
    .table {
      min-width: 1300px;
      .thead {
        .th {
          background-color: #f5f5f5;
        }
      }
      .tbody {
        .tr{
          &:nth-child(2n) {
            .td {
              background-color: #f5f5f5;
            }
          }
          &:nth-child(2n + 1) {
            .td {
              background-color: #f9f9f9;
            }
          }
        }
      }
      .th,.td {
        &:nth-child(1),
        &:nth-child(5),
        &:nth-child(6){
          width: 30%;
        }

        &:nth-child(4),
        &:nth-child(7),
        &:nth-child(8){
          width: 40%;
        }

         &:nth-child(1){
          position: sticky;
          left: 0;
         }
         &:nth-child(2){
          position: sticky;
          left: 97px;
         }
         &:nth-child(3){
          position: sticky;
          left: 254px;
         }
      }
    }
  }
  .no-data {
    img {
      margin-top: 30px!important;
    }
  }
}
</style>