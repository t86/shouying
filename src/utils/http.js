import axios from '../request/http.js';
import getTermType from '../request/addTermType';
import { sessionStorage, localStorage } from '@/utils/common/storage'
import Axios from 'axios';
import { Message } from 'element-ui'
/**
 * get方法，对应get请求
 * param {String} url [请求的url地址]
 * param {Object} params [请求时携带的参数]
 */
function get(url, params) {
  return new Promise((resolve, reject) => {
    axios.get(url, {
      params: params
    }).then(res => {
      resolve(res.data);
    }).catch(err => {
      reject(err.data)
    })
  });
}
/**
 * post方法，对应post请求
 * param {String} url [请求的url地址]
 * param {Object} params [请求时携带的参数]
 */
function post(url, params, loading = false) {
  return new Promise((resolve, reject) => {
    axios.post(url, params, { custom: {loading: loading}})
      .then(res => {
        // console.log(res);
        resolve(res.data);
      })
      .catch(err => {
        // console.log(err);
        reject(err.data)
      })
  });
}
// 为下载二进制流封装一个请求
function binaryFileGet(url, params) {
  return new Promise((resolve, reject) => {
    axios({
      methods: 'GET',
      url: url,
      responseType: 'blob',
      params: params
    }).then(res => {
      resolve(res.data);
    }).catch(err => {
      reject(err.data)
    })
  });
}

// 为下载二进制流封装一个请求
function binaryFilePost(url, params) {
  return new Promise((resolve, reject) => {
    Axios({
      method: 'POST',
      url: url,
      data: params,
      headers: {tk: localStorage.getItem("tk"),tt: getTermType(url)},
      responseType: 'blob'
    }).then(res => {

      // if(res.headers['content-type'] != 'application/octet-stream'){
      //   return Message({
      //     message: '读取导出数据出现异常',
      //     type: 'error'
      //   })
      // } 
      
      if(res.headers['content-disposition']) res.data.fileName = res.headers['content-disposition'].split('=')[1]
      resolve(res.data);
    }).catch(err => {
      reject(err.data)
    })
  });
}

// 为上传二进制流封装一个请求
function handleUploadFile(url, param, fileBlob) {
  return new Promise((resolve, reject) => {
    let formData = new FormData();
    for (let i in param) {
      formData.append(i, param[i]);
    }
    formData.append("file", fileBlob);
    Axios.post(url, formData).then(res => {
      resolve(res.data);
    }).catch(err => {
      reject(err.data)
    })


  });
}

export default {get, post, binaryFilePost, binaryFileGet, handleUploadFile}