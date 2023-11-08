<template>
  <div>
    <!-- 新增或修改部门/员工 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5 erp-lib-detail fs14">
        <!-- 新增或编辑部门 -->
        <div v-if="type == 11 || type == 12">
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span>上级部门：</span>
            </div>
            <div class="value">{{groupName}}</div>
          </div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span class="red-color">*</span>
              <span>子部门：</span>
            </div>
            <div class="value">
              <el-input v-model="groupSonName"  @input="limitingRule('groupSonName')" size="small" placeholder="请输入子部门名称"></el-input>
            </div>
          </div>
        </div>
        <!-- 新增或编辑或类似创建员工 -->
        <div v-if="type == 21 || type == 22 || type == 23">
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span>上级部门：</span>
            </div>
            <div class="value">{{groupName || parentName}}</div>
          </div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span class="red-color">*</span>
              <span>姓名：</span>
            </div>
            <div class="value">
              <el-input v-model="empName" autocomplete="off" @input="limitingRule('empName')" size="small" placeholder="请输入姓名"></el-input>
            </div>
          </div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span>拼音：</span>
            </div>
            <div class="value">{{pyName}}</div>
          </div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span class="red-color">*</span>
              <span>岗位：</span>
            </div>
            <div class="value">
              <el-select v-model="stationVal" size="small">
                <el-option :value="item.id" :label="item.n" v-for="item in stationOption" :key="item.id"></el-option>
              </el-select>
            </div>
          </div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span class="red-color">*</span>
              <span>工号：</span>
            </div>
            <div class="value">
              <el-input v-model="code"  @input="limitingRule('code')" size="small" placeholder="请输入工号"></el-input>
            </div>
          </div>
          <div class="red-color fs12 m-l-10 p-l-10 m-t-2 m-b-2">可使用系统自动生成的编号，也可以手动修改(长度不超过8，只支持数字)</div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span class="red-color">*</span>
              <span>性别：</span>
            </div>
            <div class="value">
              <el-radio v-model="sex" :label="1">男</el-radio>
              <el-radio v-model="sex" :label="2">女</el-radio>
            </div>
          </div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span>员工直属上级：</span>
            </div>
            <div class="value">
              <el-select
                autocomplete="off"
                v-model="upperEmpId"
                filterable
                remote
                clearable
                reserve-keyword
                placeholder="请输入姓名或工号"
                :remote-method="remoteEmpHandle"
                :loading="loading">
                <el-option
                  v-for="item in upperEmpOption"
                  :key="item.id"
                  :label="item.n"
                  :value="item.id">
                </el-option>
              </el-select>
            </div>
          </div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span>替身：</span>
            </div>
            <div class="value">
              <el-select
                v-model="cloneEmpId"
                filterable
                remote
                clearable
                reserve-keyword
                placeholder="请输入姓名或工号"
                :remote-method="remoteCloneEmpHandle"
                :loading="loading">
                <el-option
                  v-for="item in cloneEmpOption"
                  :key="item.id"
                  :label="item.n"
                  :value="item.id">
                </el-option>
              </el-select>
            </div>
          </div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span>电话：</span>
            </div>
            <div class="value">
              <el-input v-model="phoneNum"  @change="limitingRule('phoneNum')" size="small" placeholder="请输入电话"></el-input>
            </div>
          </div>
        </div>
      </div>


      
      <!-- 新建员工，员工工号出现冲突  模态框 -->
      <div layout="row" style="width:100vw;height:100vw;background:rgba(0,0,0,.3);position:fixed;left:0;top:0;z-index:999" @keyup.esc="showMakeCardModal=false" v-if="showReloadEmpCodeModal">
        <div style="padding:30px 20px;width:400px;background:#fefefe;position:absolute;top:40vh;left:50%;transform:translate(-50%,-50%);border-radius:10px">
          <p style="margin:40px;line-height:30px;text-align:center;">{{reloadModelText}}，是否重新获取最新工号？</p>
          <div layout="row" layout-align="center center">
            <el-button type="info" @click="showReloadEmpCodeModal = false">取消</el-button>
            <el-button type="primary" @click="getEmpCode">确认</el-button>
          </div>
        </div>
      </div>

      <!-- 删除员工出现冲突 -->
      <drawerNextDrawer 
        v-model="showNextDrawer" 
        :effectType="23" 
        :nexDrawerInfo="nexDrawerInfo"  
        @getMenuList="$emit('getMenuList')"
        @onCancelDrawer="onCancelDrawer"
      />

      <!-- 员工批量修改密码 -->
      <drawerEmpOther 
        v-model="showOtherDrawer"
        :otherType="4"
        :checkedList="[{...currentInfo}]"
        @onCancelDrawer="onCancelDrawer"
      />

      
      <!-- 绑定员工 -->
      <drawerBindEmp 
        v-model="showBindEmpDrawer"
        :currentBindPersonInfo="currentEmpInfo"
      />

      
      <!-- 制卡/清卡操作模态框 -->
      <div layout="row" style="width:100vw;height:100vw;background:rgba(0,0,0,.3);position:fixed;left:0;top:0;z-index:999999" @keyup.esc="showMakeCardModal=false" v-if="showMakeCardModal">
        <div style="padding:30px 20px;width:400px;background:#fefefe;position:absolute;top:40vh;left:50%;transform:translate(-50%,-50%);border-radius:10px">
          <p style="line-height:100px;text-align:center;font-size:20px">请将卡片放置于读卡器感应区</p>
          <div style="width:80px;height:36px;margin:20px auto 0;line-height:36px;border-radius:8px;background:#ccc;text-align:center;cursor:pointer" @click="showMakeCardModal=false">取消操作</div>
        </div>
      </div>


      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
        <el-button v-if="isSearch && type == 22" type="danger" @click="deleteEmpHandle">删除</el-button>
        <el-button v-if="isSearch && type == 22 && currentEmpInfo.wc==1" type="danger" @click="destoryCard">作废卡</el-button>
        <el-button v-if="isSearch && type == 22" type="primary" @click="showOtherDrawer = true">重置密码</el-button>
        <el-button v-if="isSearch && type == 22" type="primary" @click="makeCardHandle">{{currentEmpInfo.wc == 1 ? '清卡' : '制卡'}}</el-button>
        <!-- <el-button v-if="isSearch && type == 22" type="primary" @click="showOrHideBindHandle">{{currentEmpInfo.bs == '未绑定'?'绑定员工': currentEmpInfo.bs=='已绑定' ? '解除绑定' : '解绑中'}}</el-button> -->
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      showMakeCardModal: false, // 制卡/清卡操作模态框

      groupSonName: '',

      currentEmpInfo: {}, // 当前员工的所有信息
      parentName: '', // 员工上级部门  // 用于菜单搜索修改员工信息
      parentId: '', // 员工上级部门id  // 用于菜单搜索修改员工信息

      empName: '',
      pyName: '',
      stationVal: '',
      stationOption: [],
      code: '',
      sex: 1,
      upperEmpId: '', // 员工直属上级
      upperEmpOption: [], // 员工直属上级option
      cloneEmpId: '', // 替身
      cloneEmpOption: [], // 替身option
      phoneNum: '',
      loading: false, // 远程搜索的时候是否显示loading

      showBindEmpDrawer: false, // 绑定员工微信

      // 是否显示新建员工时的员工工号发生冲突的模态框
      showReloadEmpCodeModal: false,
      reloadModelText: '',

      showNextDrawer: false, // 有效无效删除冲突时的下一步操作drawer
      nexDrawerInfo: {
        ns: [],
        cs: []
      },

      showOtherDrawer: false,  // 重置密码
    };
  },
  methods: {
    async getDetail() {
      const params = {
        id: this.currentInfo.id * 1
      };
      try {
        const res = this.type == 12 ? await this.$api.BMS.dept.requestdeptGet(params) : await this.$api.BMS.emp.requestEmpGet(params)
        if (res.code == 1) {
          if(this.type == 12) {
            this.groupSonName = res.data.name
          } else {
            this.currentEmpInfo = res.data.emp || {}
            this.parentName = res.data.emp.dept_name || ""
            this.parentId = res.data.emp.dept_id || ''
            
            this.stationVal = res.data.emp.station_id || ''
            this.stationOption = res.data.stations || []
            if (this.type != 23) {
              this.code = res.data.emp.code
              this.sex = res.data.emp.sex
              this.empName = res.data.emp.name || ''
              this.pyName = res.data.emp.name_py || ''
              this.phoneNum = res.data.emp.phone_num
            }
            this.upperEmpId = res.data.emp.upper_emp_id ? res.data.emp.upper_emp_id + "" : ""
            this.upperEmpOption = res.data.emp.upper_emp_id ? [{
              id: res.data.emp.upper_emp_id + "", 
              n: res.data.emp.upper_emp_name
            }] : []
            this.cloneEmpId = res.data.emp.clone_emp_id ? res.data.emp.clone_emp_id + "" : ""
            this.cloneEmpOption = res.data.emp.clone_emp_id ? [{
              id: res.data.emp.clone_emp_id + "", 
              n: res.data.emp.clone_emp_name
            }] : []

          }

        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("数据请求失败", error);
      }
    },

    async getEmpCode(){
      try {
        const res = await this.$api.BMS.emp.requestEmpGencode()
        if(res.code == 1) {
          this.code = res.data || ''
        } else {
          this.message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }
    },

    async getPyName(){
      const params = {
        str: this.empName || ''
      }
      try {
        const res = await this.$api.UtilAuth.util.requestutilpy(params)
        if(res.code == 1) {
          this.pyName = res.data || ''
        } else {
          this.message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取员工姓名拼音失败', error);
      }
    },

    async getStationOption(){
      try {
        const res = await this.$api.BMS.emp.requestStationList()
        if(res.code == 1) {
          this.stationOption = res.data || []
        } else {
          this.message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }
    },

    async remoteEmpHandle(query){
      if (query !== '') {
        this.loading = true;
        const params = {
          name: query,
          page_num: 1,
          page_size: 9999999,
          mod_emp_ids: []
        }
        try {
          const res = await this.$api.BMS.emp.requestEmpUpperItems(params)
          if(res.code == 1) {
            this.upperEmpOption = res.data || []
            this.loading = false;
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log('远程搜索失败', error); 
        }
      } else {
        this.upperEmpOption = [];
      }
    },

    async remoteCloneEmpHandle(query){
      if (query !== '') {
        this.loading = true;
        const params = {
          name: query,
          page_num: 1,
          page_size: 9999999,
          mod_emp_ids: []
        }
        try {
          const res = await this.$api.BMS.emp.requestEmpUpperItems(params)
          if(res.code == 1) {
            this.cloneEmpOption = res.data || []
            this.loading = false;
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log('远程搜索失败', error); 
        }
      } else {
        this.cloneEmpOption = [];
      }
    },

    
    // 显示或隐藏绑定员工的drawer
    showOrHideBindHandle(){
      if(this.currentEmpInfo.bs == '解绑中' && !this.showBindEmpDrawer) return this.$message.warning('解绑中，请勿操作')
      this.showBindEmpDrawer = !this.showBindEmpDrawer
    },

    // 输入规则
    limitingRule(name){
      switch (name) {
        case 'groupSonName':
          if (this.groupSonName == '') {
            this.$message.warning('请输入子部门名称')
          } else if(this.$overall.character(this.groupSonName) > 10) {
            this.$message.warning('子部门长度超过5')
          }
          break
        case 'empName':
          if (this.empName == '') {
            this.$message.warning('请输入员工姓名')
          } else if(this.$overall.character(this.empName) > 20) {
            this.$message.warning('姓名长度不可超过10')
          }
          this.getPyName()
          break
        case 'code':
          if (this.code == '') {
            this.$message.warning('请输入工号')
          } else if(this.$overall.character(this.code) > 8) {
            this.$message.warning('工号长度不可超过8')
          }
          break
        case 'phoneNum':
          if (this.phoneNum.length != 11 ) {
            this.$message.warning('请输入11位电话')
          }
          break
      }
    },

    // 删除员工
    async deleteEmpHandle() {
      const params = {
        ids: [this.currentInfo.id * 1]
      }
      try {
        const res = await this.$api.BMS.emp.requestEmpDel(params)
        if (res.code == 1) {
          this.$message.success('操作成功')
          this.onCancelDrawer()
          if(this.isSearch) this.$emit('initSearchValHandle')
        } else if (res.code == 2) {
          this.showNextDrawer = true
          this.nexDrawerInfo.ns = res.data.ns || []
          this.nexDrawerInfo.cs = res.data.cs || []
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('删除员工失败', error);
      }
    },

    
    /**
     * 制卡
     */
    makeCardHandle(){
      const itemInfo = this.currentEmpInfo || {}
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
            console.log('制卡失败', e)
          }
        } else {
          this.$message.warning(res.msg)
          this.showMakeCardModal = false
        }
      } catch (error) {
        this.showMakeCardModal = false
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
          this.onCancelDrawer()
          this.showMakeCardModal = false
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
        this.showMakeCardModal = false
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
          this.onCancelDrawer()
          this.showMakeCardModal = false
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
    async destoryCard(){
      const params = {
        emp_id: this.currentEmpInfo.id * 1  //   int64  员工Id
      }

      try {
        const res = await this.$api.BMS.emp.reqDestoryCard(params)
        if(res.code == 1) {
          this.$message.success('作废卡成功')
          this.onCancelDrawer()
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('作废失败', error)
      }
    },

    async onSubmit() {
      let params = {}
      let method = ''
      let api = ''
      if(this.type == 11) {
        // 新增部门
        if(this.groupSonName == '') return this.$message.warning('请输入子部门名称')
        params = {
          pid: this.menuId ? this.menuId * 1 : 0,
          name: this.groupSonName || '',
        }
        method = 'dept'
        api = 'requestdeptNew'
      } else if(this.type == 12) {
        // 修改部门
        if(this.groupSonName == '') return this.$message.warning('请输入子部门名称')
        params = {
          id: this.currentInfo.id,
          name: this.groupSonName || '',
        }
        method = 'dept'
        api = 'requestdeptSave'
      } else if(this.type == 21 || this.type == 23) {
        // 新建员工
        if(this.empName == '') return this.$message.warning('请输入员工名称')
        if(this.stationVal == '') return this.$message.warning('请选择岗位')
        if(this.code == '') return this.$message.warning('请输入工号名称')
        params = {
          depot_id: this.menuId ? this.menuId * 1 : 0, //部门Id
          name: this.empName,  //员工姓名
          station_id: this.stationVal * 1, //岗位Id
          name_py: this.pyName,   //NamePy 员工姓名拼音首字母
          code: this.code,    //Code 员工工号
          sex: this.sex,     //Sex 性别 1 男 2 女
          phone_num: this.phoneNum,   //PhoneNum 联系电话
          upper_emp_id: this.upperEmpId * 1,   //UpperEmpId 直属上级
          clone_emp_id: this.cloneEmpId * 1, // int64  替身
        }
        method = 'emp'
        api = 'requestEmpNew'
      } else if(this.type == 22) {
        // 修改员工 类似创建
        if(this.empName == '') return this.$message.warning('请输入员工名称')
        if(this.stationVal == '') return this.$message.warning('请选择岗位')
        if(this.code == '') return this.$message.warning('请输入工号名称')
        params = {
          id: this.currentInfo.id * 1, // int64  员工id
          dept_id: this.isSearch ? this.parentId * 1 : (this.menuId ? this.menuId * 1 : 0), // int64 部门Id
          name: this.empName,  // string 员工姓名
          station_id: this.stationVal * 1, // int64  岗位Id
          name_py: this.pyName,   //string   员工姓名拼音首字母
          code: this.code,    //string 员工工号
          sex: this.sex * 1,     //int  性别 1 男 2 女
          phone_num: this.phoneNum,   //string  联系电话
          upper_emp_id: this.upperEmpId * 1,   //int64 直属上级
          clone_emp_id: this.cloneEmpId * 1, // int64  替身
        }
        method = 'emp'
        api = 'requestEmpSave'
      }
      try {
        const res = await this.$api.BMS[method][api](params)
        if(res.code == 1) {
          this.$message.success('操作成功')
          this.onCancelDrawer()
          if(this.isSearch) {
            this.$emit('initSearchValHandle')
          } else {
            this.$emit('getTableData')
            this.$emit('getMenuList')
          }
        } else if((this.type == 21 || this.type == 23) && res.code == 2) {
          this.reloadModelText = res.msg
          this.showReloadEmpCodeModal = true
        } else if (res.code == 6) {
          this.onCancelDrawer()
          if(this.isSearch) {
            this.$emit('initSearchValHandle')
          } else {
            this.$emit('getTableData')
            this.$emit('getMenuList')
          }
          this.$message.warning("创建成功，状态无效，" + res.msg)
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据提交失败', error);
      }
    },

    resetHandle(){
      this.empName = ''
      this.pyName = ''
      this.stationVal = ''
      this.code = ''
      this.sex = 1
      this.upperEmpId = ''
      this.upperEmpOption = []
      this.cloneEmpId = ''
      this.cloneEmpOption = []
      this.phoneNum = ''
    },
    
    onCancelDrawer() {
      this.show = false;
    }
  },
  mounted() {},
  props: {
    value: {
      default: false // 是否显示drawer
    },
    currentInfo: {
      default: () => ({}) // 当前被修改的部门/员工/ 类似创建
    },
    type: {
      default: 1  // 11：新增部门  12：修改部门  21：新增员工  22：修改员工
    },
    menuList: {
      default: () => ([])
    },
    menuId: '',
    isSearch: false, // 是否是菜单栏搜索
  },
  computed: {
    title() {
      let title = ''
      switch (this.type) {
        case 11:
          title = '新增部门'
          break
        case 12:
          title = '编辑部门'
          break
        case 21:
          title = '新增员工'
          break
        case 22:
          title = '编辑员工'
        case 23:
          title = '类似创建员工'
          break
      }
      return title
    },

    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      }
    },

    groupName(){
      let currentMenuInfo = {}
      const fn = arr => {
        arr.forEach(el => {
          if(el.id == this.menuId) {
            currentMenuInfo = {...el}
          } else {
            el.subs && fn(el.subs)
          }
        })
      }
      fn(this.menuList)
      return currentMenuInfo.n || (this.type == 11 || this.type == 12 ? '顶级' : '')
    }
  },

  components: {
    drawerNextDrawer: () => import('./drawerNextDrawer.vue'),
    drawerEmpOther: () => import('./drawerEmpOther.vue'),
    drawerBindEmp: () => import('./drawerBindEmp.vue'),
  },


  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          if(this.type == 12 || this.type == 22) {
            // 编辑部门/员工
            this.getDetail()
          } else if(this.type == 21) {
            // 新建员工
            this.getEmpCode()
            this.getStationOption()
          } else if(this.type == 23) {
            // 类似创建员工
            this.getDetail()
            this.getEmpCode()
            this.getStationOption()
          } else {
            // 新增部门
            this.groupSonName = ''
          }
        } else {
          this.resetHandle()
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../../../../style/common/elementDrawerWine.less";
@import "../../../../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../../../../style/common/elementFormBtnWine.less";
@import "../../../../../../../style/erp/form.less";
@import "../../../../../../../style/erp/table.less";
</style>

<style lang="less" scoped>
.coll {
  margin-top: 16px;
  .label {
    width: 120px;
  }
}
</style>