<template>
  <div>
    <!-- 批量导入 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      :size="size"
    >
      <div class="session p-5 fs14">
        <div v-show="!showImportResult ">
          <div
            v-if="status==1"
            style="margin-top:20px;color:rgb(217, 217, 217)"
            layout="row"
            layout-align="space-around center"
          >
            <div
              class="m-t-3"
              style="color:#438dfd;cursor:pointer;"
              @click="status=2"
            >仅导入物料</div>
            <div
              class="m-t-3"
              style="color:#438dfd;cursor:pointer;"
              @click="status=3"
            >同时导入物料和收银商品</div>
          </div>

          <div v-else class="m-t-4" style="text-align:center">
            <el-upload
              class="upload-demo"
              drag
              :action="http"
              :headers="tk"
              :on-success="succeed"
              :on-error="error"
              :on-progress="progress"
              :with-credentials="true"
              ref="ToLeadItem"
              name="impfile"
              multiple
            >
              <div style="margin: 35px 0 10px;">
                <img style="height: 70px;width: 67px;" :src="require('@/assets/img/upload_file.png')" alt />
              </div>
              <div class="el-upload__text">
                将文件拖到此处，或
                <span class="primary-link">点击上传</span>
              </div>
              <div class="el-upload__tip" slot="tip" style="color: #8C8C8C;">只支持上传xlsx文件</div>
            </el-upload>
            <div
              class="primary-link cursor"
              style="text-align: center;margin: 5px 0;"
              @click="downloadTemplate"
            >点击下载模板</div>
            <div
              class="red-color"
              style="text-align: center;"
            >！导入后将新增物料{{status==2?'':'和收银商品'}}</div>
          </div>
        </div>

        <div v-show="showImportResult">
          <div class="red-color fs14">
            共导入{{ImportData.length}}条数据，成功处理{{dataAnalysis}}条，可选择成功处理的正常数据导入或根据反馈信息修改后重新导入
            <br />*号标识代表必填项，没有则为选填
            <br />此序号对应文档中序号
          </div>
          <h3 class="m-t-2 m-b-2">反馈信息:</h3>
          <div class="table-content">
            <div class="table">
              <div class="thead">
                <div class="tr" layout="row" layout-align="space-between center">
                  <div class="th">
                    <el-checkbox
                      :indeterminate="isIndeterminatedata"
                      v-model="checkAlldata"
                      @change="changeImportDataHandle"
                    >序号 1,2</el-checkbox>
                  </div>
                  <div class="th">物料名称</div>
                  <div class="th">{{status==3?'物料':''}}一级分类</div>
                  <div class="th">{{status==3?'物料':''}}二级分类</div>
                  <div class="th">物料单位</div>
                  <div class="th">空瓶回收</div>
                  <div class="th" v-if="status==3">收银商品名称</div>
                  <div class="th" v-if="status==3">收银商品一级分类</div>
                  <div class="th" v-if="status==3">收银商品二级分类</div>
                  <div class="th" v-if="status==3">收银商品类型</div>
                  <div class="th" v-if="status==3">收银商品价格</div>
                  <div class="th">结果反馈</div>
                </div>
              </div>
              <div class="tbody"
                :style="{
                  'width':ImportData.length>4?'calc(100% + 6px)':'100%',
                  'border-bottom':ImportData.length<1?'0px':''}"
              >
                <div class="tr" layout="row" layout-align="space-between center" v-for="(item, i) in ImportData" :key="item.id">
                  <div class="td">
                    <el-checkbox-group
                      v-model="checkedCitiesdata"
                      @change="changeImportItemDataHandle"
                    >
                      <el-checkbox :disabled="whetherForbidden[i]" :label="item.ids">{{i+3}}</el-checkbox>
                    </el-checkbox-group>
                  </div>
                  <div class="td">{{item.names}}</div>
                  <div class="td">{{item.mat_one_cate_names}}</div>
                  <div class="td">{{item.mat_two_cate_names}}</div>
                  <div class="td">{{item.unit_names}}</div>
                  <div class="td">{{item.rtn_bottle}}</div>
                  <div class="td" v-if="status==3" >{{item.prd_names}}</div>
                  <div class="td" v-if="status==3" >{{item.prd_one_cate_names}}</div>
                  <div class="td" v-if="status==3" >{{item.prd_two_cate_names}}</div>
                  <div class="td" v-if="status==3" >{{item.prd_types }}</div>
                  <div class="td" v-if="status==3" >{{item.prices}}</div>
                  <div class="td" layout="row" layout-align="start center">
                    <div
                      v-if="!whetherForbidden[i]"
                      class="primary-link"
                    >
                      正常数据
                      <span v-for="(result, si) in item.err_msgs" :key="si">{{result}}</span>
                    </div>
                    <div
                      v-else
                      class="red-color"
                      v-for="(result, si) in item.err_msgs"
                      :key="si"
                    >{{result}}</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button v-if="showImportResult" type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import { projectName, projectConfig } from '@/utils/config/projectConfig.js'
import { sessionStorage, localStorage } from '@/utils/common/storage'
export default {
  data() {
    return {
      showImportResult: false, // 是否显示导入结果
      status: 1,  // 1:批量导入  2：批量导入物料  3：批量导入物料及收银商品
      ImportData: [], //所有的商品导入信息
      dataAnalysis: "", //成功处理多少条数据
      tk: { tk: localStorage.getItem("tk"), tt: '64' }, //token
      whetherForbidden: [], //判断是否禁用

      checkAlldata: false, //全部选中触发
      checkedCitiesdata: [], //已选择内容
      isIndeterminatedata: false, //全选或者全不选
    };
  },
  methods: {
    // 下载批量导入模板
    async downloadTemplate() {
      // status : 2:仅导入物料  3： 导入物料和收银商品
      const downLoadApi = this.status == 2 ? "requestmattpl" : "requestmatAndProTpl";
      try {
        const res = await this.$api.ERP.mat[downLoadApi]()
        const url = window.URL.createObjectURL(
          new Blob([res], {
            type:
              "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
          })
        );
        const a = document.createElement("a"); //添加a标签
        document.body.appendChild(a);
        a.href = url;
        a.setAttribute("download", res.fileName); // 下载文件的名称及文件类型后缀
        a.click(); //点击标签
        document.body.removeChild(a); // 下载完成移除元素
        window.URL.revokeObjectURL(url); // 释放掉blob对象
      } catch (error) {
        // 下载模板失败
        console.log('下载模板失败', error);
      }
    },
    
    // 上传成功
    succeed(response, file, fileList) {
      this.loading.close();
      if (response.code == 1 || response.code == 2) {
        this.ImportData = [];
        let s = {};
        this.whetherForbidden = [];
        this.checkAlldata = false;
        this.isIndeterminatedata = false;
        this.checkedCitiesdata = [];

        // 有错误数据
        if (response.data.err_ids) {
          for (const key in response.data.ids) {
            s =
              this.status == 2
                ? {
                    names: response.data.names[key] || "",
                    ids: response.data.ids[key] || "",
                    unit_names: response.data.unit_names[key] || "",
                    mat_one_cate_names:
                      response.data.mat_one_cate_names[key] || "",
                    mat_two_cate_names:
                      response.data.mat_two_cate_names[key] || "",
                    rtn_bottle: response.data.rtn_bottle[key] || ""
                  }
                : {
                    names: response.data.mat_names[key] || "",
                    ids: response.data.ids[key] || "",
                    unit_names: response.data.unit_names[key] || "",
                    mat_one_cate_names:
                      response.data.mat_one_cate_names[key] || "",
                    mat_two_cate_names:
                      response.data.mat_two_cate_names[key] || "",
                    prd_names: response.data.prd_names[key] || "",
                    prd_one_cate_names:
                      response.data.prd_one_cate_names[key] || "",
                    prd_two_cate_names:
                      response.data.prd_two_cate_names[key] || "",
                    prd_types: response.data.prd_types[key] || "",
                    prices: response.data.prices[key] || "",
                    // member_prices: response.data.member_prices[key] || "",
                    rtn_bottle: response.data.rtn_bottle[key] || ""
                  };

            const findIndex = response.data.err_ids.findIndex(
              item => item == s.ids
            );
            s.disabled = findIndex > -1;
            s.err_msgs = response.data.err_msgs[findIndex] || "";

            this.ImportData.push(s);
          }
          this.whetherForbidden = this.ImportData.map(item => item.disabled);

          let id = response.data.ids;

          for (let i = 0; i < response.data.ids.length; i++) {
            for (let j = 0; j < response.data.err_ids.length; j++) {
              if (id[i] == response.data.err_ids[j]) {
                id.splice(i, 1);
                i = i - 1;
              }
            }
          }
          this.checkedCitiesdata = id || [];
          if (id.length > 0) {
            this.isIndeterminatedata = true;
          }
          this.dataAnalysis = response.data.ids.length;
        } else {
          for (const key in response.data.ids) {
            this.whetherForbidden.push(false);
            this.checkedCitiesdata.push(response.data.ids[key] || "");
            this.isIndeterminatedata = false;
            this.checkAlldata = true;

            const s =
              this.status == 2
                ? {
                    names: response.data.names[key] || "",
                    ids: response.data.ids[key] || "",
                    unit_names: response.data.unit_names[key] || "",
                    mat_one_cate_names:
                      response.data.mat_one_cate_names[key] || "",
                    mat_two_cate_names:
                      response.data.mat_two_cate_names[key] || "",
                    rtn_bottle: response.data.rtn_bottle[key] || ""
                  }
                : {
                    names: response.data.mat_names[key] || "",
                    ids: response.data.ids[key] || "",
                    unit_names: response.data.unit_names[key] || "",
                    mat_one_cate_names:
                      response.data.mat_one_cate_names[key] || "",
                    mat_two_cate_names:
                      response.data.mat_two_cate_names[key] || "",
                    prd_names: response.data.prd_names[key] || "",
                    prd_one_cate_names:
                      response.data.prd_one_cate_names[key] || "",
                    prd_two_cate_names:
                      response.data.prd_two_cate_names[key] || "",
                    prd_types: response.data.prd_types[key] || "",
                    prices: response.data.prices[key] || "",
                    // member_prices: response.data.member_prices[key] || "",
                    rtn_bottle: response.data.rtn_bottle[key] || ""
                  };
            this.ImportData.push(s);
          }
          this.dataAnalysis = response.data.ids.length;
        }
        this.showImportResult = true;
        // 清空列表
        this.$refs.ToLeadItem.clearFiles();
      } else {
        this.$message({ message: response.msg, type: "warning" });
      }
    },
    // 上传失败
    error() {
      this.loading.close(); 
      this.$message.warning("上传失败,请重新上传")
    },
    // 上传时
    progress() {
      const loading = this.$loading({
        lock: true,
        text: "上传中",
        spinner: "el-icon-loading",
        background: "rgba(0, 0, 0, 0.7)"
      });
      this.loading = loading;
    },
    // 清空导入列表信息
    clearImportData() {
      this.showImportResult = false;
      // 清空列表
      this.$refs.ToLeadItem.clearFiles();
    },
    
    // 控制批量导入全选或者全不选
    changeImportDataHandle(val) {
      if (val) {
        this.checkedCitiesdata = [];
        for (const key in this.ImportData) {
          if (!this.ImportData[key].err_msgs) {
            this.checkedCitiesdata.push(this.ImportData[key].ids);
          }
        }
      } else {
        this.checkedCitiesdata = [];
      }
      this.isIndeterminatedata = false;
      this.$forceUpdate()
    },
    // 控制批量导入单个选中
    changeImportItemDataHandle(value) {
      let checkedCount = value.length;
      this.checkAlldata = checkedCount === this.ImportData.length;
      this.isIndeterminatedata = checkedCount > 0 && checkedCount < this.ImportData.length;
    },

    // 提交导入数据
    async onSubmit() {
      if (this.checkedCitiesdata.length > 0) {
        const s =
          this.status == 2
            ? {
                ids: [],
                names: [],
                mat_one_cate_names: [],
                mat_two_cate_names: [],
                unit_names: [],
                rtn_bottle: []
              }
            : {
                ids: [], //        []int     数据序号
                mat_names: [], //  []string  存货物料名称
                mat_one_cate_names: [], // []string   存货物料一级分类名称
                mat_two_cate_names: [], // []string   存货物料二级分类名称
                unit_names: [], // []string   物料/商品单位名称
                rtn_bottle: [], // []string   空瓶回收,有/无
                prd_names: [], //  []string   收银商品名称
                prd_one_cate_names: [], // []string   收银商品一级分类名称
                prd_two_cate_names: [], // []string   收银商品二级分类名称
                prd_types: [], //  []string   收银商品类型 单品(主营) 单品(非主营) 单品(非主营分成) 花篮 小费 赔偿 联营
                prices: [], //     []string   收银商品单价
              };
        for (const i in this.whetherForbidden) {
          if (!this.whetherForbidden[i]) {
            for (const key in this.checkedCitiesdata) {
              if (this.checkedCitiesdata[key] == this.ImportData[i].ids) {
                s.ids.push(this.ImportData[i].ids);
                s.mat_one_cate_names.push(
                  this.ImportData[i].mat_one_cate_names
                );
                s.mat_two_cate_names.push(
                  this.ImportData[i].mat_two_cate_names
                );
                s.unit_names.push(this.ImportData[i].unit_names);
                s.rtn_bottle.push(this.ImportData[i].rtn_bottle);
                if (this.status == 2) {
                  // 导入物料
                  s.names.push(this.ImportData[i].names);
                }
                if (this.status == 3) {
                  // 导入物料和收银商品
                  s.mat_names.push(this.ImportData[i].names)
                  s.prd_names.push(this.ImportData[i].prd_names)
                  s.prd_one_cate_names.push(this.ImportData[i].prd_one_cate_names)
                  s.prd_two_cate_names.push(this.ImportData[i].prd_two_cate_names)
                  s.prd_types.push(this.ImportData[i].prd_types)
                  s.prices.push(this.ImportData[i].prices)
                }
              }
            }
          }
        }
        const apiInterface = this.status == 2 ? 'requestmatimp': 'requestmatAndMoneyimp'
        this.$api.ERP.mat[apiInterface](s).then(res => {
          if (res.code == 1) {
            this.$message.success('导入成功')
            this.$emit('getTableData')
            this.$emit('getMenuList')
            this.onCancelDrawer()
            // 清空列表
            this.$refs.ToLeadItem.clearFiles();
          } else {
            this.$message({
              showClose: true,
              message: res.msg,
              type: "warning"
            });
          }
        });
      } else {
        this.$message({
          message: "请选择一个物料再进行操作",
          type: "warning"
        });
      }
    },
    onCancelDrawer() {
      this.clearImportData()
      this.show = false;
    }
  },
  mounted() {},
  props: {
    value: {
      default: false // 是否显示drawer
    }
  },
  computed: {
    title() {
      return this.status == 1 ? "批量导入" : this.status == 2 ? '批量导入物料' : '批量导入物料及收银商品';
    },

    size(){
      if(this.showImportResult) {
        return '98%'
      } else {
        return this.status == 1 ? "500px" : this.status == 2 ? '600px' : '600px';
      }
    },

    http() {
      const matHttp =
        (process.env.NODE_ENV === "development"
          ? projectConfig[projectName]['development'] : projectConfig[projectName]['product']) + "/mat/imp_chk";
      const matAndMontyHttp =
        (process.env.NODE_ENV === "development"
          ? projectConfig[projectName]['development'] : projectConfig[projectName]['product']) + "/mat/imp_with_prd_chk";
      return this.status == 2 ? matHttp : matAndMontyHttp;
    },

    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      }
    }
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.status = 1
          this.showImportResult = false
        }
      },
      immediate: true
    },
  }
};
</script>

<style scoped lang="less">
@import "../../../../../../style/common/elementDrawerWine.less";
@import "../../../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../../../style/common/elementFormBtnWine.less";
@import "../../../../../../style/erp/form.less";
@import "../../../../../../style/erp/table.less";
</style>
<style lang="less" scoped>
.table-content {
  .table {
    height: calc(100vh - 250px);
    overflow: auto;
    .th,.td{
      &:nth-child(1) {
        width: 40%;
      }
    }
  }
}
</style>