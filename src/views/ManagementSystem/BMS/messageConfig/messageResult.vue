<template>
  <div class="message-detail">
    <div  class="mt-4" layout="row" layout-align="start center">
      <div class="ml-4">手机号：</div>
      <div class="value m-r-2">
        <el-input
            style="width:260px"
            v-model="phone"
        ></el-input>
      </div>
      <el-button class="m-l-3" type="primary" size="small" @click="getTableData()">查询</el-button>
      <el-button size="small" @click="resetHandle">重置</el-button>
    </div>

    <el-table
        class="ml-4 m-t-8"
        :data="tableData"
        border>
      <el-table-column
          type="index"
          label="序号"
          width="60">
      </el-table-column>
      <el-table-column
          prop="m"
          label="手机号码"
          width="120">
      </el-table-column>
      <el-table-column
          prop="t"
          label="短信类型"
          width="200">

        <template slot-scope="scope">
          {{getTemplateData(scope.row.t).n}}
        </template>

      </el-table-column>

      <el-table-column
          prop="t"
          label="发送内容">
        <template slot-scope="scope">
          {{getTemplateData(scope.row.t).t}}
        </template>
      </el-table-column>

      <el-table-column
          prop="c"
          width="60"
          label="条数">
      </el-table-column>
        <el-table-column
            prop="s"
            width="110"
            label="发送结果">
      </el-table-column>
      <el-table-column
          prop="r"
          width="160"
          label="发送时间">
      </el-table-column>
      <el-table-column
          prop="d"
          width="160"
          label="接收时间">
      </el-table-column>
      <el-table-column
          prop="e"
          width="180"
          label="失败原因">
      </el-table-column>
    </el-table>

  </div>
</template>

<script>
export default {
  data() {
    return {
      phone: '',
      tableData: [],
      templates: [],
    };
  },
  methods: {
    async getTableData(init) {
      const params = {
        mobile: this.phone
      };

      try {
        const res = await this.$api.BMS.messageConfig.get_mobile_send_rst(params)
        if (res.code === 1) {
          this.templates = res.data.sms_template || []
          this.tableData = res.data.records || []
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("列表数据获取失败", error);
      }
    },

    getTemplateData(id) {
      let find = this.templates.find(item => item.id === id);
      if (find) {
        return  {
          n: find.n,
          t: find.t
        }
      }
      return {n: '', t: ''}


    },



    resetHandle() {
      this.phone  = ''
    }
  },
  components: {
  }
};
</script>
