<template>
  <div class="upload-img">
    <el-upload
      action
      multiple
      :limit="200"
      accept=".jpg, .png, .jpeg"
      :show-file-list="false"
      :with-credentials="true"
      :http-request="uploadRequest"
      :on-change="handleChange"
      :on-exceed="masterFileMax"
    >
      <el-button size="small" @click="resetUploadPicInfoHandle" type="primary">批量上传</el-button>
      <div class="upload-tips red-color">
        <p>批量上传图片重要说明：</p>
        <p>1. 支持图片格式：png, jpg，jpeg，且大小不超过500k。请按照菜品或套餐名称命名图片文件，如：轩尼诗vsop.png。</p>
        <p>2. 单次上传最多200张图片，多次上传同名称菜品图片将以最后上传的为准。</p>
        <p>3. 上传图片支持多选，可按住 Ctrl 选择多张图片或者按Ctrl+A 全选文件夹内的图片。</p>
        <p>4. 以上规则有任意一项错误，图片将上传失败。上传过程中请不要刷新页面或做其它操作。</p>
      </div>
    </el-upload>

    <!-- 上传图片列表 -->
    <div class="check-list" v-if="showUploadDrawer">
      <h3>反馈信息：</h3>
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-around center">
            <div class="th">
              <el-checkbox v-model="checked" @change="changeCheckboxHandle('all')">序号</el-checkbox>
            </div>
            <div class="th">商品名称</div>
            <div class="th">商品图片</div>
            <div class="th">结果反馈</div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="tr"
            layout="row"
            layout-align="space-around center"
            v-for="(item,index) in uploadPicInfo"
            :key="index"
          >
            <div class="td">
              <el-checkbox
                @change="changeCheckboxHandle('item', item)"
                v-model="item.checked"
                :disabled="item.disabled"
              >{{index+1}}</el-checkbox>
            </div>
            <div class="td">{{item.name}}</div>
            <div class="td" layout="row" layout-align="start center">
              <img :src="item.srcUrl" alt />
            </div>
            <div class="td red" v-if="item.id<=0">{{item.id==-1?'图片大于500k':'未检测到对应商品'}}</div>
            <div class="td green" v-else>已匹配</div>
          </div>
        </div>
      </div>

      <div class="btn m-t-4" layout="row" layout-align="end center">
        <!-- <el-button type="primary">重新导入</el-button> -->
        <el-button type="info" @click.native="showUploadDrawer=false">取消</el-button>
        <el-button type="primary" @click.native="submitHandle">导入选中</el-button>
      </div>
    </div>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      picNameList: [],
      uploadPicInfo: [],
      showUploadDrawer: false,
      checked: true
    };
  },
  methods: {
    resetUploadPicInfoHandle() {
      this.uploadPicInfo = [];
    },
    masterFileMax(files, fileList) {
      this.$message.warning(`请最多上传200个文件。`);
    },
    uploadRequest(params) {
      if (!params.file) return;
      this.showUploadDrawer = true;
      if (params.file.size / 1024 >= 500) {
        this.uploadPicInfo.push({
          name: params.file.name.split(".")[0],
          id: -1,
          disabled: true,
          srcUrl: URL.createObjectURL(params.file)
        });
        return;
      } else {
        this.uploadPicInfo.push({
          name: params.file.name.split(".")[0],
          params: params,
          uploadSuccess: false,
          srcUrl: URL.createObjectURL(params.file)
        });
      }

      this.picNameList = [...this.picNameList, params.file.name.split(".")[0]];
      const length = this.picNameList.length;

      setTimeout(() => {
        if (length == this.picNameList.length) {
          this.checkProImgHandle(this.picNameList);
        }
      }, 500);
    },

    handleChange(file, fileList) {},

    // 商品批量上传图片检查
    async checkProImgHandle(pic_names = []) {
      this.loading = this.$loading({
        lock: true,
        text: "Loading",
        spinner: "el-icon-loading",
        background: "rgba(0, 0, 0, 0.7)"
      });
      const params = {
        pic_names //  []string     //PicNames 待验证的商品图片名称(去掉后缀后的名字)
      };

      try {
        const res = await this.$api.BMS.Prd.reqCheckProImg(params);
        if (res.code == 1) {
          this.uploadPicInfo.forEach(el => {
            const find = res.data.items.find(item => item.n == el.name);
            if (el.id || el.id == 0) {
              // 未匹配
            } else if (find) {
              el.checked = false // find.id && find.id != 0;
              el.disabled = true // !(find.id && find.id != 0);
              el.id = find.id;
            }
          });
          this.uploadAllImg();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("上传商品图片失败", error);
      }

      this.$nextTick(() => {
        this.loading.close();
      }, 2000);
    },

    uploadAllImg() {
      const indexList = []
      this.uploadPicInfo
        .filter(item => item.id > 0)
        .forEach(el => {
          this.$api.BMS.Prd.requestOssPt().then(item => {
            let res = item.data;
            let src = this.$overall.generateUUID() + "." + el.params.file.name.split(".")[1];
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
              el.params.file
            ).then(async resp => {
              this.uploadPicInfo.forEach(ele => {
                if(ele.name == el.name) {
                  ele.uploadSuccess = true
                  ele.checked = true
                  ele.src = src
                  ele.disabled = false
                }
              })
              this.$forceUpdate();
            });
          });
        });
    },

    // 单选全选
    changeCheckboxHandle(type) {
      switch (type) {
        case "all":
          const uploadPicInfo = [...this.uploadPicInfo];
          uploadPicInfo.forEach(el => {
            el.checked = el.disabled ? false : this.checked;
          });
          this.uploadPicInfo = [...uploadPicInfo];
          break;
        case "item":
          this.checked = this.uploadPicInfo.filter(item => !item.disabled).every(item => item.checked);
          break;
      }
      this.$forceUpdate()
    },
    async submitHandle() {
      const params = {
        ids: this.uploadPicInfo
          .filter(item => item.checked)
          .map(item => item.id * 1), //   []int64   待上传商品图片的商品Id
        pic_names: this.uploadPicInfo
          .filter(item => item.checked)
          .map(item => item.src) //  []string  对应商品Id的,商品图片的uuid名称,带后缀 (url前缀要去掉)
      };

      console.log('params', params)

      try {
        const res = await this.$api.BMS.Prd.reqUploadProImg(params);
        if (res.code == 1) {
          this.$message.success("上传成功");
          this.showUploadDrawer = false;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("批量上传失败", error);
      }
    }
  }
};
</script>

<style scoped lang="less">
.upload-img {
  text-align: left;
  /deep/.el-upload {
    text-align: left !important;
  }
  .upload-tips {
    margin-top: 20px;
    p {
      font-size: 14px;
      line-height: 30px;
    }
  }
}

// 上传列表
.check-list {
  padding: 40px;
  width: 90vw;
  height: 100vh;
  position: fixed;
  box-sizing: border-box;
  right: 0;
  top: 0;
  background-color: #f9f9f9;
  box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1);
  h3 {
    padding-bottom: 20px;
    color: #1a1a21;
  }
  .table {
    // background-color: #111;
    color: #40404e;
    .thead {
      background-color: #f5f5f5;
      /deep/.el-checkbox__label,
      .th {
        font-weight: 600;
        color: #1a1a21;
        font-size: 14px;
      }
    }
    .tbody {
      height: calc(100vh - 200px);
      overflow-y: auto;
      font-size: 14px;
      .tr:nth-child(2n) {
        background-color: #f5f5f5;
      }
    }
    .tr {
      padding: 8px 10px;
      line-height: 30px;
      .th,
      .td {
        padding: 0 6px;
      }
      img {
        width: 20%;
      }
      .td.red {
        color: #ec808d;
      }
      .td.green {
        color: rgb(127, 184, 43);
      }
      .th:nth-child(1),
      .td:nth-child(1) {
        width: 10%;
      }
      .th:nth-child(2),
      .td:nth-child(2) {
        width: 30%;
      }
      .th:nth-child(3),
      .td:nth-child(3) {
        width: 30%;
      }
      .th:nth-child(4),
      .td:nth-child(4) {
        width: 30%;
      }
    }
  }
}
</style>