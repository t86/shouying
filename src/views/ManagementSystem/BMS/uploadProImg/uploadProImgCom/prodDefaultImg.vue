<template>
  <div class="pro-default">

    <div class="coll" layout="row" layout-align="start center">
      <div class="label">菜单显示图片：</div>
      <el-switch v-model="mode" active-color="#2170ff"
                  active-text="是"
                  inactive-text="否"
      >
      </el-switch>
    </div>
    <div class="coll" layout="row" layout-align="start center">
      <div class="label" style=""></div>
      <div class="value" layout="column" layout-align="center start">
        <h5 class="color-red m-t-2 m-b-2">开关关闭：点单时菜单不显示商品图片</h5>
        <h5 class="color-red">开关开启：点单时菜单显示商品对应的图片</h5>
      </div>
    </div>
    <div class="coll m-t-4" layout="row" layout-align="start center">
      <div class="label">商品默认图片：</div>
      <!-- 使用element plus 添加上传图片组件 -->
      <el-upload
      v-if="!imageUrl"
        class="upload-menu-pic"
        ref="uploadRef"
        :limit="1"
        accept=".jpg, .png, .jpeg"
        :show-file-list="false"
        :with-credentials="true"
        :http-request="uploadRequest"
      >
        <div class="img" layout="row" layout-align="center center">
          <img :src="require(`@/assets/vip-imgs/bgi-add.png`)" alt />
        </div>
      </el-upload>
      <!-- 自适应宽高 -->
      <img  class="default-img" v-else :src="imageUrl" alt />
    </div>
    <div class="coll m-t-2 m-b-2" layout="row" layout-align="start center">
      <div class="label" style=""></div>
      <div  v-if="imageUrl" class="value" layout="row" layout-align="start start">
        <!-- 查看大图是个可点击的链接，不要下划线，蓝色字体-->
        <a href="javascript:;" @click="showLargeImage" class="color-blue m-r-4 m-l-6">查看大图</a>
        <a href="javascript:;" @click="deleteImage" class="color-blue">删除</a>
      </div>
    </div>

    <div class="coll" layout="row" layout-align="start center">
      <div class="label" style=""></div>
      <div class="value" layout="column" layout-align="center start">
        <h5 class="color-red m-t-2 m-b-2">说明：</h5>
        <h5 class="color-red">1.点击上传图片，仅支持：jpg、png的格式</h5>
        <h5 class="color-red">2.商品未上传图片时，当前图片作为默认图片在手机端或电脑端显示</h5>
        <h5 class="color-red">3.如未上传商品默认图片，则将使用系统默认图片</h5>
      </div>
    </div>

    <div v-if="showModal" class="modal" @click="closeModal">
      <div class="modal-content" @click.stop>
        <img :src="imageUrl" class="large-image">
        <button class="close-button" @click="closeModal">X</button>
      </div>
    </div>

    <div class="coll m-t-8 m-l-10" layout="row" layout-align="start center">
      <el-button type="primary" @click="onSubmit">保存</el-button>
    </div>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      menuShowPic: false,
      imageUrl: '', // 用于存储图片的 URL
      mode: false,  //Mode 1 开启 2 关闭
      showModal: false, // 展示大图
      srcFile: '',
    };
  },
  methods: {
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
          this.srcFile = src;
          this.imageUrl = item.data.host + '/' + key;
        });
      });
    },

    async uploadImg(prdName) {
      const params = {
        mode: this.mode ? 1 : 2, //Mode 1 开启 2 关闭
        def_pic_name: prdName //DefPicName 默认商品图片名称,为空代表没有或删除
      };
      try {
        const res = await this.$api.BMS.Prd.reqSavePrdDefPic(params);
        if(res.code == 1) {
          this.$message.success('默认图片上传成功')
          this.getDefImg()
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log('默认图片上传失败', error)
      }
    },
    async getDefImg(){
      try {
        const res = await this.$api.BMS.Prd.reqGetPrdDefPic();
        if(res.code == 1) {
          this.mode = res.data.mode == 1
          if(res.data.def_pic_name) {
            this.imageUrl = res.data.pic_prefix + res.data.def_pic_name
            this.srcFile = res.data.def_pic_name
          }
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log('默认图片获取失败', error)
      }
    },
    showLargeImage(){
      this.showModal = true
    },
    closeModal(){
      this.showModal = false
    },
    async deleteImage(){
      this.srcFile = ''
      this.imageUrl = ''
    },
    onSubmit() {
      this.uploadImg(this.srcFile);
    }
  },
  created() {
    this.getDefImg()
  },
  computed: {

  }
};
</script>

<style scoped lang="less">
.pro-default {
  color: #40404e;
  position: relative;


  .label {
    width: 140px;
    text-align: left;
    margin-right: 20px;
  }
  .value {
    width: 100%;
    font-size: 16px;
    .el-switch {
      width: 40px;
    }
    a {
      font-size: 14px;
    }
  }

  .upload-menu-pic {
    width: 100px;
    height: 100px;
    border: 1px dashed #dcdfe6;
    border-radius: 4px;
    cursor: pointer;
    background: #dcdfe6;
    // 图片居中显示
    .img {
      width: 100px;
      height: 100px;
      align-items: center;
      img {
        width: 30px;
        height: 30px;
      }
    }
  }

  // 图片使用自适应宽高的方式
  .default-img {
    width: 100px;
    height: 100px;
    border: 1px dashed #dcdfe6;
    border-radius: 4px;
    cursor: pointer;
    background: #dcdfe6;
    object-fit: contain;
  }

  .modal {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.5);
    display: flex;
    justify-content: center;
    align-items: center;
  }

  .large-image {
    max-width: 90%;
    max-height: 90%;
  }

  .modal-content {
    position: relative;
    .close-button {
      position: absolute;
      top: 10px;
      right: 10px;
      /* ... */
    }
  }

}
</style>  