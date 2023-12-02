<template>
  <div class="pro-default">
      <!-- 使用element plus 添加上传图片组件 -->
      <el-upload
        class="upload-demo"
        ref="uploadRef"
        action
        :limit="1"
        accept=".jpg, .png, .jpeg"
        :show-file-list="false"
        :with-credentials="true"
        :http-request="uploadRequest"
      >
        <div class="img" layout="row" layout-align="center center">
          <img :src="okImg" alt />
        </div>
      </el-upload>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      okImg: ''
    };
  },
  methods: {
    
  },
  created() {
  },
  computed: {

  }
};
</script>

<style scoped lang="less">
.pro-default {
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