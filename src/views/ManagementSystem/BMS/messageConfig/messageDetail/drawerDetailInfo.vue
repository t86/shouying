<template>
  <div>
   <el-drawer
     :title='title'
     :visible.sync='show'
     :before-close='onCancelDrawer'
     direction='rtl'
     size='90%'
   >
    <div class='session p-5 fs14'>
      <div class="tips fs18 red-color m-b-3">
        <span>{{currentInfo.d}}</span>
        <span class="m-l-6">发送短信：{{currentInfo.sc * 1 + currentInfo.fc * 1}}条</span>
        <span class="m-l-6">成功：{{currentInfo.sc}}条</span>
        <span class="m-l-6">失败：{{currentInfo.fc}}条</span>
      </div>
      <div class="top">
        <span>状态：</span>
        <el-select v-model="selectVal" size="small" style="width:100px" placeholder="请选择">
          <el-option
            v-for="item in options"
            :key="item.value"
            :label="item.label"
            :value="item.value"
          ></el-option>
        </el-select>

        <el-input placeholder="手机号码" size="small" style="width:150px" v-model="keyword"></el-input>

        <el-button type="primary" size="small" @click="getTableData(1)">查询</el-button>
        <el-button size="small" @click="resetHandle">重置</el-button>
      </div>

      
    <div class="table-content m-t-4">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">序号</div>
            <div class="th">手机号码</div>
            <div class="th">短信类型</div>
            <div class="th">发送短信内容</div>
            <div class="th" layout="row" layout-align="start center">
              <span class="m-r-1">字数|条数</span>
              <span class="pointer tips-icon" style="position:relative">
                <svg t="1692440611911" class="icon" viewBox="0 0 1024 1024" version="1.1" xmlns="http://www.w3.org/2000/svg" p-id="4033" width="16" height="16"><path d="M512 127.9c51.9 0 102.2 10.1 149.5 30.2 45.7 19.3 86.8 47 122.1 82.3s63 76.4 82.3 122.1c20 47.3 30.2 97.6 30.2 149.5S886 614.2 865.9 661.5c-19.3 45.7-47 86.8-82.3 122.1s-76.4 63-122.1 82.3c-47.3 20-97.6 30.2-149.5 30.2S409.8 886 362.5 865.9c-45.7-19.3-86.8-47-122.1-82.3s-63-76.4-82.3-122.1c-20-47.3-30.2-97.6-30.2-149.5s10.1-102.2 30.2-149.5c19.3-45.7 47-86.8 82.3-122.1s76.4-63 122.1-82.3c47.3-20 97.6-30.2 149.5-30.2m0-64C264.5 63.9 63.9 264.5 63.9 512S264.5 960.1 512 960.1 960.1 759.5 960.1 512 759.5 63.9 512 63.9z" p-id="4034"></path><path d="M480 736h64v64h-64z m-3.1-49.7c-0.3-9.3-0.4-42.2-0.4-46.8 0-27.3 3.9-50.8 11.6-70.6 5.7-14.9 14.8-30 27.4-45.1 9.3-11.1 25.9-27.2 50-48.4 24-21.2 39.7-38.1 46.9-50.7s10.8-26.4 10.8-41.3c0-27-10.5-50.7-31.6-71.2-21.1-20.4-46.9-30.7-77.5-30.7-29.6 0-54.3 9.3-74.1 27.8-19.8 18.5-32.8 47.4-39 86.8l-71.4-8.5c6.4-52.7 25.5-93.1 57.3-121.1s73.7-42 125.9-42c55.3 0 99.4 15 132.3 45.1 32.9 30.1 49.4 66.5 49.4 109.2 0 24.7-5.8 47.4-17.4 68.3s-34.2 46.2-67.9 76c-22.6 20.1-37.4 34.8-44.4 44.4-6.9 9.5-12.1 20.4-15.4 32.8-3.3 12.3-5.3 58.4-5.8 86.2h-66.7v-0.2z" p-id="4035"></path></svg>
                <span class="tips-text" style="position:absolute;left:-250px;bottom:25px;width:400px;padding:6px 10px;background:#ddd;border-radius:8px;font-weight:400;text-align:justify">
                  短信长度（签名+正文）不超过70字时，按照1条短信计费；超过70字即为长短信时，按67字/条分隔成多条计费。例如，短信长度为150字，则按照67字/67字/16字分隔成3条计费。
                </span>
              </span>
            </div>
            <div class="th">发送时间</div>
            <div class="th">接收时间</div>
            <div class="th">发送状态</div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" v-for="(item, index) in tableData" :key="item.id" layout="row" layout-align="space-between center">
            <div class="td">{{index + 1}}</div>
            <div class="th">{{item.m}}</div>
            <div class="td">{{item.type}}</div>
            <div class="td">{{item.tpl}}</div>
            <div class="td">{{item.tpl.length}} | {{item.c}}</div>
            <div class="td">{{item.r}}</div>
            <div class="td">{{item.d}}</div>
            <div class="td" :class="[item.s == '成功' ? 'green' : 'red-color']">{{item.s}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img src="@/assets/img/wu.png" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
      <div class="fr m-t-4">
        <el-pagination
          background
          layout="prev, pager, next"
          @current-change="changePageHandle"
          :page-size="pageInfo.pageSize"
          :total="pageInfo.total">
        </el-pagination>
      </div>
    </div>
    </div>
    <div class='form-btn' layout='row' layout-align='center center'>
      <el-button type='info' @click='onCancelDrawer'>关闭</el-button>
    </div>
    </el-drawer>
  </div>
</template>
 
<script>
  export default {
    data() {
      return {
        startTime: '',
        endTime: '',
        selectVal: 0,
        options:[{
          label: '全部',
          value: 0
        },{
          label: '成功',
          value: 1
        },{
          label: '失败',
          value: 2
        }],
        keyword: '',
        tableData: [],
        tplList: [],
        pageInfo: {
          page: 1,
          pageSize: 20,
          total: 0
        },
      }
    },
    methods: {
      async getTableData(init = 2){
        const params = {
          page_num: this.pageInfo.page * 1, //   int    指定第几页
          page_size: this.pageInfo.pageSize * 1, //  int     每页行数
          is_init: init, //    int     1 初始化, 短信模板信息,用于还原短信消息内容,及计算字数 2 非初始化
          record_id: this.currentInfo.id * 1, //  int64   日账单Id
          status: this.selectVal * 1, //     int     0 全部 1 成功 2 失败
          mobile: this.keyword || '', //   string  手机号,模糊查询
        }
        try {
          const res = await this.$api.BMS.messageConfig.reqGetMsgDayDataDetail(params)
          if(res.code == 1) {
            // TODO:
            if(init == 1) this.tplList = res.data.sms_types || []
            this.tableData = (res.data.records || []).map(item => {
              const tplInfo = this.tplList.find(items => items.id == item.t) || {}
              return {
                ...item,
                tpl: tplInfo.t.replace('{1}', item.p1).replace('{2}', item.p2).replace('{3}', item.p3).replace('{4}', item.p4).replace('{5}', item.p5).replace('{6}', item.p6),
                type: tplInfo.n
            }})

            console.log(this.tableData);

            this.pageInfo.total = res.data.row_cnt || 0
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log('数据请求失败', error);
        }
      
      },

          
      changePageHandle(page) {
        this.pageInfo.page = page
        this.getTableData()
      },

      resetHandle() {
        this.selectVal = 0
        this.keyword = ''
        this.getTableData(1)
      },
      
      onCancelDrawer() {
        this.show = false
      }
    },
    created() {
    },
    mounted() {
 
    },
    props: {
      value: {
        default: false
      },
      currentInfo: {
        default: () => ({})
      }
    },
    computed: {
      title() {
        return '短信账单明细'
      },
      show: {
        get() {
          return this.value
        },
        set(val) {
          this.$emit('input', val)
        }
      }
    },
    watch: {
      value: {
        handler(newVal) {
          if (newVal) {
            this.getTableData(1)
          }
        },
        immediate: true
     }
   }
 }
 
</script>

<style scoped lang='less'>
@import '../../../../../style/common/elementDrawerWine.less';
@import '../../../../../style/common/elementDrawerHeaderAndSession.less';
@import '../../../../../style/common/elementFormBtnWine.less';
@import '../../../../../style/erp/form.less';
@import '../../../../../style/erp/table.less';
</style>
<style scoped lang='less'>
.table-content {
  .table{
    .tbody {
      height: calc(100vh - 320px);
      overflow: auto;
    }

    .tr{
      padding: 6px 0;
    }

    .th,.td {
      &:nth-child(1),
      &:nth-child(5),
      &:nth-child(8) {
        width: 25%;
      }
      &:nth-child(2){
        width: 40%;
      }
      &:nth-child(4) {
        width: 70%;
      }
      
      &:nth-child(6),
      &:nth-child(7) {
        width: 30%;
      }
    }

    .tips-icon {
      cursor: pointer;
      .tips-text{
        display: none;
      }

      &:hover{
        .tips-text{
          display: block;
        }
      }
    }

    .green {
      color: green;
    }
  }
}
</style>