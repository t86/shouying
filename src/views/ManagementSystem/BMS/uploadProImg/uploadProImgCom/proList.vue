<template>
  <div class="pro-list">
    <div class="top" v-if="loaded">
      <div class="img" layout="row" layout-align="center center">
        <img :src="okImg" alt />
      </div>
      <p>检测完毕，以下{{allPrdCount}}个单品/套餐尚无图片</p>
      <p class="red-color">点击商品名称可上传图片</p>
    </div>
    <!-- table -->
    <div class="table">
      <div class="thead">
        <div class="tr" layout="row" layout-align="start center">
          <div class="th"><span class="p-l-5">一级分类</span></div>
          <div class="th"><span class="p-l-5">商品名称</span></div>
        </div>
      </div>
      <div class="tbody">
        <div
          class="tr"
          v-for="(item,index) in tableData"
          :key="index"
          layout="row"
          layout-align="start center"
        >
          <div class="td p-l-5" style="font-weight:600"><span class="p-l-5">{{item.n}}</span></div>
          <div class="td">
            <div
              class="td-td"
              title="点击可上传图片"
              v-for="items in item.p"
              :key="items.id"
              @click="getCurrentPrdInfo(item, items)"
            >
              <el-upload
                action
                :limit="1"
                accept=".jpg, .png, .jpeg"
                :show-file-list="false"
                :with-credentials="true"
                :http-request="uploadRequest"
              >
                <span class="p-l-5">{{items.n}}</span>
              </el-upload>
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
</template>
 
<script>
import okImg from "@/assets/mgr-img/ok.png";
export default {
  data() {
    return {
      tableData: [],
      okImg,
      loaded: false,

      upload: {
        firstCateInfo: {},
        currentPrdInfo: {}
      }
    };
  },
  methods: {
    async getTableData() {
      this.loading = this.$loading({
        lock: true,
        text: "Loading",
        spinner: "el-icon-loading",
        background: "rgba(0, 0, 0, 0.7)"
      });
      try {
        const res = await this.$api.BMS.Prd.reqCheckNoProImgList();
        res.code == 1
          ? (this.tableData = (res.data.cates || []).map(item => ({
              ...item,
              p: item.p || []
            })))
          : this.$message.warning(res.msg);
      } catch (error) {
        console.log("获取为上传图片的商品列表失败", error);
      }
      this.loading.close();
      this.loaded = true;
    },

    getCurrentPrdInfo(item, items) {
      this.upload.firstCateInfo = {...item}
      this.upload.currentPrdInfo = { ...items };
    },

    uploadRequest(params) {
      if (!params.file) return;

      if (params.file.size / 1024 >= 500) {
        return this.$message.warning("图片大于500K，上传失败");
      }

      this.$api.BMS.Prd.requestOssPt().then(item => {
        let res = item.data;
        let name = params.file.name.split(".")[0];
        let src =
          this.$overall.generateUUID() + "." + params.file.name.split(".")[1];
        let key = res.dir + src;
        this.$api.BMS.Prd.handleUploadFile(
          res.host,
          {
            key: key,
            policy: res.policy,
            OSSAccessKeyId: res.accessid,
            success_action_status: "200", //让服务端返回200,不然，默认会返回204
            signature: res.signature
          },
          params.file
        ).then(() => {
          this.uploadImg(src);
        });
      });
    },

    async uploadImg(prdName) {
      const params = {
        prd_id: this.upload.currentPrdInfo.id * 1, //   int64  商品Id
        prd_name: prdName //   string     //PicName 对应商品Id的,商品图片的uuid名称,带后缀 (url前缀要去掉)
      };
      try {
        const res = await this.$api.BMS.Prd.reqUploadSingleImg(params);
        if(res.code == 1) {
          let tableData = [...this.tableData]
          const find = tableData.find(item => item.n == this.upload.firstCateInfo.n)
          if(find && find.p.length == 1) {
            // 当前一级分类下只有一个商品
            const index = tableData.findIndex(item => item.n == this.upload.firstCateInfo.n)
            if(index > -1) tableData.splice(index, 1)
          } else {
            const index = find.p.findIndex(item => item.id == this.upload.currentPrdInfo.id)
            if(index > -1) find.p.splice(index, 1)
          }

          this.tableData = [...tableData]

        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log('图片上传失败', error)
      }
    }
  },
  created() {
    this.getTableData();
  },
  computed: {
    allPrdCount() {
      return this.tableData.map(item => item.p).flat().length;
    }
  }
};
</script>

<style scoped lang="less">
.pro-list {
  color: #40404e;
  .top {
    text-align: center;
    .img {
      margin: 0 auto;
      width: 50px;
      height: 50px;
      border-radius: 50%;
      background-color: rgb(9, 187, 7);
      img {
        width: 70%;
      }
    }
    p {
      padding: 10px;
    }
  }
  .table {
    font-size: 14px;

    .tr {
      width: 100%;
      min-height: 40px;
      padding: 0 5px;
      box-sizing: border-box;

      .th,
      .td {
        padding: 0 5px;
        text-align: left;
        &:nth-child(1) {
          width: 30%;
        }
        &:nth-child(2) {
          width: 80%;
          .td-td {
            line-height: 34px;
            cursor: pointer;
            color: #2170ff;
            &:hover{
              background-color: #eee;
            }
          }
        }
      }
    }

    .thead {
      position: sticky;
      top: 0;
      z-index: 9;

      .tr {
        background-color: #f5f5f5;
        font-weight: 600;

        .el-checkbox__label {
          font-weight: 600;
        }
      }
    }

    .tbody {
      background-color: #f9f9f9;
      height: calc(100vh - 330px);
      overflow: auto;

      .tr:nth-child(2n) {
        background-color: #f5f5f5;
      }

      .no-data {
        padding: 40px 0;
        text-align: center;

        img {
          margin-bottom: 10px;
          width: 60px;
        }
      }
    }
  }
}
</style>  