<template>
  <div class="smgrs">
    <div class="in_sum-rkrq" layout="row" layout-align="start center">
      <div class="coll" layout="row" layout-align="start center">
        <span>部门：</span>
        <el-cascader
          size="small" 
          style="wdith:200px"
          v-model="dept_code"
          :options="dept_items"
          clearable
          ></el-cascader>
      </div>
      <div class="m-l-2">
        <span>岗位：</span>
        <el-select v-model="station_code" placeholder="全部" size="small" style="wdith:200px" clearable>
          <el-option label="全部" value></el-option>
          <el-option v-for="(item) in post" :key="item.id" :label="item.n" :value="item.id"></el-option>
        </el-select>
      </div>
      <div class="m-l-2">
        <el-input v-model="name" placeholder="请输入工号或姓名" style="wdith:200px" size="small"></el-input>
      </div>
      <div class="m-l-2">
        <el-button type="primary" @click="getTableData" size="small">查询</el-button>
      </div>
    </div>
    <div class="table-content m-t-3">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">岗位名称</div>
            <div class="th">岗位下员工数</div>
            <div class="th">岗位状态</div>
            <div class="th">操作</div>
            <div class="th">更改状态</div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" v-for="item in tableData" :key="item.id">
            <div class="coll" layout="row" layout-align="space-between center">
              <div class="td" layout="row" layout-align="center center">
                <i class="m-r-2" style="border:1px solid #ccc;cursor:pointer" @click="item.show = !item.show" :class="[item.show ? 'el-icon-minus' : 'el-icon-plus']"></i>
                <span style="width :120px;text-align:left">{{item.n}}</span>
              </div>
              <div class="td">{{item.c}}</div>
              <div class="td">{{item.s}}</div>
              <div class="td">
                <span class="link" @click="setOrCancelAdmin(item)">{{item.a == 1 ? '收回管理员' : '设为管理员'}}</span>
              </div>
              <div class="td">
                <span class="link" @click="setStationEffect(item)">置为有效</span>
              </div>
            </div>
            <div class="detail-list" v-if="item.show">
              <div class="tr-thead" layout="row" layout-align="space-between center">
                <div class="tr-th" style="width:20%"></div>
                <div class="tr-th">员工编号</div>
                <div class="tr-th">员工姓名</div>
                <div class="tr-th">部门名称</div>
                <div class="tr-th">状态</div>
                <div class="tr-th">重置密码</div>
                <div class="tr-th">更改状态</div>
                <div class="tr-th" style="width:20%"></div>
              </div>
               <div class="tr-tbody">
                <div
                  class="tr-tr"
                  layout="row"
                  layout-align="space-between center"
                  v-for="(items, index) in (item.es || [])"
                  :key="index"
                >
                  <div class="tr-td" style="width:20%"></div>
                  <div class="tr-td">{{items.c}}</div>
                  <div class="tr-td">{{items.n}}</div>
                  <div class="tr-td">{{items.d}}</div>
                  <div class="tr-td">{{items.s}}</div>
                  <div class="tr-td">
                    <span class="link" @click="restPassWord(items)">重置密码</span>
                  </div>
                  <div class="tr-td">
                    <span class="link" @click="checkStatusHandle(items)">置位{{items.s=='有效'?'无效':'有效'}}</span>
                  </div>
                  <div class="tr-td" style="width:20%"></div>
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
  </div>
</template>
<script>
export default {
  data() {
    return {
      tableData: [], //员工数据
      dept_code: [], //部门编码
      dept_items: [], //部门信息
      post: [], // 岗位信息
      station_code: "", //岗位编码
      name: "", //工号或姓名 模糊查询
      optionProps: {
        value: "id",
        label: "n",
        children: "subs",
        checkStrictly: true,
        expandTrigger: "hover"
      }
    };
  },
  mounted() {
    this.getTableData(1);
  },
  computed: {},
  methods: {
    // 获取用户列表
    async getTableData(isInit) {
      const params = {
        is_init: isInit == 1 ? 1 : 2, //    int  1 页面初始化, 返回部门岗位结构; 2 非初始化
        dept_id: this.dept_code[this.dept_code.length - 1] || 0, //    int64   部门ID
        station_id: this.station_code, // int64    岗位ID
        name: this.name //  string   工号或姓名 模糊查询
      }

      try {
        const res = await this.$api.UtilAuth.appinfo.requestsmgremps(params)
        if(res.code == 1) {
            this.tableData = (res.data.station_emps || []).map(item => ({
              ...item,
              show: this.tableData.find(items => items.id == item.id) ? this.tableData.find(items => items.id == item.id).show : false
            }))
            if(isInit == 1) {
              res.data.depts = res.data.depts || []
              this.dept_items = []
              res.data.depts.map(item => ({
                ...item,
                value: item.id,
                label: item.n,
                children: (item.subs || []).map(items => ({
                  label: items.n,
                  value: item.id
                }))
              })).forEach(el => {
                if(el.children.length == 0){
                  this.dept_items.push({
                    value: el.id,
                    label: el.n
                  })
                } else {
                  this.dept_items.push({
                    value: el.id,
                    label: el.n,
                    children: el.children
                  })
                }
              })
              this.post = res.data.stations || []
            }
          } else {
            this.$message.warning(res.msg);
          }
      } catch (error) {
        console.log('表格数据获取失败', error)
      }
    },

    // 设置岗位有效
    async setStationEffect(itemInfo){
      const params = {
        station_id: itemInfo.id * 1  // int64   岗位Id
      }
      try {
        const res = await  this.$api.UtilAuth.appinfo.reqSetStationEffect(params)
        if(res.code == 1) {
          this.getTableData()
          this.$message.success('操作成功')
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('设置岗位有效失败')
      }
    },
    // 设为、收回岗位管理员
    async setOrCancelAdmin(itemInfo) {
      const params = {
        station_id: itemInfo.id * 1  // int64   岗位Id
      }
      const api = itemInfo.a == 1 ? 'requestsmgrrevoke' : 'requestsmgrgrant'
      try {
        const res = await this.$api.UtilAuth.appinfo[api](params)
        if(res.code == 1) {
          this.$message.success('操作成功')
          this.getTableData()
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('设置管理员失败', error)
      }
    },
    // 员工重置密码
    async restPassWord(itemInfo){
      const params = {
        emp_id: itemInfo.id * 1  // int64  待操作员工ID
      }
      try {
        const res = await this.$api.UtilAuth.appinfo.requestsmgrresetpwd(params)
        if(res.code == 1) {
          this.$message.success('重置成功')
          this.getTableData()
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('重置密码失败', error)
      }
    },
    // 员工状态修改
    async checkStatusHandle(itemInfo){
      const params = {
        emp_id: itemInfo.id * 1 // int64  待操作员工ID
      }
      const api = itemInfo.s == '有效' ? 'reqSetAuthDisabled' : 'reqSetAuthEnable'
      
      try {
        const res = await this.$api.UtilAuth.appinfo[api](params)
        if(res.code == 1){
          this.$message.success('操作成功')
          this.getTableData()
        }else{
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('设置用户状态失败', error)
      }
    }
  }
};
</script>
<style lang="less" scoped>

.table-content {
  position: relative;
  width: 100%;

  .table {
    color: #2c3e50;
    height: calc(100vh - 160px);
    overflow: auto;
    .thead {
      position: sticky;
      top: 0;
      background-color: #eee;

      .th {
        font-weight: 600;

      }
    }

    .tr {
      font-size: 14px;
      text-align: center;

      &:nth-child(2n) {
        background-color: #f5f5f5
      }
    }

    .th,
    .td {
      width: 50%;
      padding: 10px 6px;
    }

    .detail-list {
      .tr-thead {
        // background-color: #eee;
        .tr-th {
          font-weight: 600;
        }
      }

      .tr-th,.tr-td {
        padding: 10px 0;
        width: 50%;
        font-size: 13px;
      }
    }
  }

  .link {
    color: #2170ff;
    cursor: pointer;
  }

  .no-data {
    text-align: center;

    img {
      margin-top: 80px;
      width: 60px;
    }

    p {
      margin-top: 10px;
      font-size: 14px;
    }
  }
}
</style>



