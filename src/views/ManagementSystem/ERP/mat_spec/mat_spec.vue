<template>
    <div class="mat_spec">
        <!-- <div class="mat_spec-headline">物料规格</div> -->
        <div class="mat_spec-controller">
            <icon-button @click.native="xingh" text="新增" img="btn_add.png" colors="#383943"></icon-button>
            <icon-button @click.native="compileprinter" text="编辑" img="btn_edit.png" colors="#383943"></icon-button>
            <icon-button @click.native="noneffective" text="置为无效" img="btn_in_vain.png" colors="#383943"></icon-button>
            <icon-button @click.native="effective" text="置为有效" img="btn_effective.png" colors="#383943"></icon-button>
            <icon-button @click.native="printerdel" text="批量删除" img="btn_delete.png" colors="#6B2830"  bjcolors="#491E24"></icon-button>
        </div>

        <div style="display: inline-block;"  class="meisfgr">
            <table class="zhuixiaoi"  style="min-width: 770px;">
                <thead class="mmodity">
                    <tr>
                        <th  >
                            <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll" @change="handleCheckAllChange">全选</el-checkbox>
                        </th>
                        <th>规格名称</th>
                        <th>创建时间</th>
                        <th>更新时间</th>
                        <th>状态</th>
                    </tr>
                </thead>
                <tbody class="limiting" :style="{'border-bottom':tableData.length<1?'0px':'',
                'width':tableData.length>MaxNumber?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`}">
                    <tr v-for="(item,i) in tableData" :key="item.id" class="drag-list"
                        :class="multipleSelection.includes(item.id)? 'drag-list-check':''">
                        <td :style="{'color':item.s=='无效'?'#595959':''}">
                            <el-checkbox-group v-model="multipleSelection" @change="handleCheckedCitiesChange">
                                <el-checkbox  :label="item.id">{{i+1}}</el-checkbox>
                            </el-checkbox-group> 
                        </td>
                        <td  :style="{'color':item.s=='无效'?'#595959':'',}">
                            <ellipsis-tooltip :text="item.n || '-----'"></ellipsis-tooltip>
                        </td>
                        <td  :style="{'color':item.s=='无效'?'#595959':'',}">
                            <ellipsis-tooltip :text="item.c || '-----'"></ellipsis-tooltip>
                        </td>
                        <td  :style="{'color':item.s=='无效'?'#595959':'',}">
                            <ellipsis-tooltip :text="item.u || '-----'"></ellipsis-tooltip>
                        </td>
                        <td  :style="{'color':item.s=='无效'?'#595959':'',}">
                            <ellipsis-tooltip :text="item.s || '-----'"></ellipsis-tooltip>
                        </td>
                    </tr>
                </tbody>
            </table>
            <div class="tiaodd" v-if="tableData.length<1">
                <td class="nodata" :style="{'height':`${MaxHeight}px !important`}">
                    <img src="../../../../assets/img/wu.png" alt="">
                    <div class="hint">暂无数据</div>
                </td>
            </div>      
        </div>


        <!-- 新增  编辑-->
        <div v-show="dialogFormVisible" class="dialogFormVisible">
            <el-dialog :title="title?'新增物料规格':'编辑物料规格'" @close="dialogFormVisible = false" :visible.sync="dialogFormVisible"  :close-on-click-modal="false">
                <el-form label-position="left">
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>物料规格：
                        </div>      
                        <el-input v-model="materialStair" @blur="limitingRule(0)" placeholder="请输入物料规格名称" ref="selectsse" class="controlling" />                                   
                        <div class="cwts">{{mistake}}</div>
                    </div>
                </el-form>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="dialogFormVisible = false">取消</el-button>
                    <el-button v-show="title" type="primary" @click="construction">新建</el-button>
                    <el-button v-show="!title" type="primary" @click="saveprinter">确认</el-button>
                </span>
            </el-dialog>
        </div>

        <!-- 无效有效删除 -->
        <div v-show="dialogFible" class="diagrgeesfelogFor">
            <el-dialog :title="srnr" :visible.sync="dialogFible" @close="dialogFible = false" :close-on-click-modal="false">
                <div class="wwent" v-show="cwsm.cs.length>0">
                    <span>以下对象存在依赖，需同步设置为{{srnr | pand}}</span>
                    <characters-button @click.native="synchronizon" :disaed="kzsfjy" colors="#383943" :wz="`同步${srnr}`"></characters-button>
                </div>
                <div class="wentlb" v-show="cwsm.cs.length>0">
                    <table class="zhuixiaoi"  >
                        <thead class="mmodity">
                            <tr>
                                <th>序号</th>
                                <th>说明</th>
                                <th>处理结果</th>
                            </tr>
                        </thead>
                        <tbody class="limiting"  :style="{'width':cwsm.cs.length>6?'calc(100% + 6px)':'100%'}">
                            <tr v-for="(item,i) in cwsm.cs"  :key="i" class="drag-list" >
                                <td>{{i+1}}</td>
                                <td>
                                    <ellipsis-tooltip :text="item.r || '-----'"></ellipsis-tooltip>
                                </td>
                                <td v-show="item.jg == '成功'" style="color: #00BC72;">{{item.jg}}</td>
                                <td v-show="item.jg == '---'">{{item.jg}}</td>
                                <td v-show="item.jg == '失败'" style="color: #E13B50;">{{item.jg}}</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <div class="wwent" v-show="cwsm.ns.length>0">以下对象存在依赖，需人工处理依赖</div>
                <div class="wentlb danykz" v-show="cwsm.ns.length>0">
                    <table class="zhuixiaoi"  >
                        <thead class="mmodity">
                            <tr>
                                <th>序号</th>
                                <th>说明</th>
                            </tr>
                        </thead>
                        <tbody class="limiting"  :style="{'width':cwsm.ns.length>6?'calc(100% + 6px)':'100%'}">
                            <tr v-for="(item,i) in cwsm.ns"  :key="i" class="drag-list" >
                                <td>{{i+1}}</td>
                                <td>
                                    <ellipsis-tooltip :text="item || '-----'"></ellipsis-tooltip>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="dialogFible = false">关闭</el-button>
                </span>
            </el-dialog>
        </div>
    </div>
</template>
<script>
import IconButton from '@/components/IconButton.vue'//根据路径导入组件
import EllipsisTooltip from '@/components/EllipsisTooltip.vue'//根据路径导入组件
import CharactersButton from '@/components/CharactersButton.vue'//根据路径导入组件
export default {
    data(){
        return{
            tableData: [],//物料规格目录
            dialogFormVisible:false,//控制新建物料规格是否显示
            materialStair:"",//物料规格名字
            title:true,//为新建还是编辑
            multipleSelection: [],// 选中的内容
            isIndeterminate:false,// 供应商选择一部分
            checkAll:false,//供应商全选

            dialogFible:false,//控制错误2是否显示
            srnr:'',//文案
            cwsm:{
                ns:[],//不可操作列表
                cs:[],//可一键操作列表
            },//错误2说明
            kzsfjy:false,//控制同步按钮是否禁用
            
            mistake:'',//弹窗内错误提示
            windowWidt: document.documentElement.clientWidth,  //实时屏幕宽度
            windowHeigh: document.documentElement.clientHeight,   //实时屏幕高度
            MaxHeight:0,//滚动高度
            MaxNumber:0//最大个数
        }
    },
    mounted(){
        this.demand()

        this.RollMaxHeight(this.windowHeigh)
        var that = this;
        window.onresize = () => {
            return (() => {
                window.fullHeight = document.documentElement.clientHeight;
                window.fullWidth = document.documentElement.clientWidth;
                that.windowHeigh = window.fullHeight;  // 高
                that.windowWidt = window.fullWidth; // 宽
            })()
        };
    },
    filters:{
        pand:function(v){
            if(v == '置为无效'){
                return '无效';
            }else if(v == '置为有效'){
                return '有效';
            }else if(v == '批量删除'){
                return '删除';
            }
            
        }
    },
    components:{
        IconButton,
        EllipsisTooltip,
        CharactersButton
    },
    computed:{
    },
    methods: {
        // 输入规则
        limitingRule(i){
            switch (Number(i)) {
              case 0: 
                console.log(this.$overall.character(this.materialStair));
                this.$refs.selectsse.$refs.input.style.borderColor = '#CE4253'
                if(this.materialStair == ''){
                    this.mistake='请输入erp仓库名称'
                }else{
                    if(this.$overall.character(this.materialStair) > 10){
                        this.mistake='输入文字长度超过5'
                    }else{
                        this.$refs.selectsse.$refs.input.style.borderColor = '#555763'
                        this.mistake=''                  
                    }
                }
                break
            }
        },
        // 重置规则样式
        czyangs(){
            this.$nextTick(()=>{  //次要代码
                this.$refs.selectsse.$refs.input.style.borderColor = '#555763'
            })
        },
        //获取焦点
        edit(){
            this.$nextTick(()=>{  //次要代码
              this.$refs.selectsse.focus();
            })
        },
        // 选择全选或取消
        handleCheckAllChange(val) {
            if(val){
                this.multipleSelection = []
                for (const key in this.tableData) {
                    this.multipleSelection.push(this.tableData[key].id)
                }
            }else{
                this.multipleSelection = []
            }
            this.isIndeterminate = false;
        },
        // 控制单个选中 
        handleCheckedCitiesChange(value) {
            let checkedCount = value.length;
            this.checkAll = checkedCount === this.tableData.length;
            this.isIndeterminate = checkedCount > 0 && checkedCount < this.tableData.length;
            // console.log(this.checkedCities);
        },
        // 获取物料规格目录
        demand(){
            this.$api.ERP.mat_spec.requestmat_speclist().then(res=>{
                console.log(res);
                if(res.code == 1){
                    this.tableData = res.data || []
                    var s = []
                    for (const iterator of this.tableData) {
                        s.push(iterator.id)
                    }
                    for(var i = 0;i<this.multipleSelection.length;i++){
                        if(s.indexOf(this.multipleSelection[i]) == -1){
                            this.multipleSelection.splice(i,1)
                        }
                    }
                }else{
                    this.$message.warning(res.msg)
                }
            })

        },
        // 为空
        weik(){
            this.multipleSelection= []
            this.isIndeterminate=false
            this.checkAll=false
        },
        // 点开创建为空
        xingh(){
            this.dialogFormVisible = true 
            this.title = true
            this.materialStair= ''  
            this.mistake = ''
            this.czyangs()   
            this.edit()  
        },
        // 创建物料规格目录
        construction(){
            for(var i=0;i<1;i++){
                this.limitingRule(i)
            }
            if(this.mistake != ''){
                this.$message.warning('请按提示正确填写')
            }else{
                this.$api.ERP.mat_spec.requestmat_specnew({
                    name:this.materialStair,
                }).then(res=>{
                    console.log(res); 
                    if(res.code == 1){
                        this.$message({
                            showClose:true,
                            message:"操作成功",
                            type:'success'
                        })
                        this.weik()
                        this.demand()
                        this.dialogFormVisible = false
                    }else{
                        this.$message.warning(res.msg)
                    }
                })
            }
        },
        // 获取编辑内容
        compileprinter(){
            if(this.multipleSelection.length == 1){
                this.$api.ERP.mat_spec.requestmat_specget({id:this.multipleSelection[0]}).then(res=>{
                    console.log(res);
                    this.materialStair = res.data.name
                    this.title = false
                    this.dialogFormVisible = true     
                    this.edit()  
                    this.mistake = ''
                    this.czyangs()   
                })
            }else {  
                this.$message({
                    message: '请选择一个进行编辑',
                    type: 'warning',
                })
            }
        },
        // 保存编辑内容
        saveprinter(){
            for(var i=0;i<1;i++){
                this.limitingRule(i)
            }
            if(this.mistake != ''){
                this.$message.warning('请按提示正确填写')
            }else{
                this.$api.ERP.mat_spec.requestmat_specsave({
                    id:this.multipleSelection[0],
                    name:this.materialStair,
                }).then(res=>{
                    console.log(res); 
                    if(res.code == 1){
                        this.$message({
                            showClose:true,
                            message:"操作成功",
                            type:'success'
                        })
                        this.weik()
                        this.demand()
                        this.dialogFormVisible = false
                    }else{
                        this.$message.warning(res.msg)
                    }
                })
            }
        },
        // 重试
        chdefrs(){
            if(this.srnr == '置为无效'){
                this.noneffective()
            }else if(this.srnr == '置为有效'){
                this.effective()
            }else if(this.srnr == '批量删除'){
                this.printerdel()
            }
        },
        // 同步
        synchronizon(){
            this.kzsfjy = true 
            var s = ''
            if(this.srnr == '置为无效'){
                s = 2
            }else if(this.srnr == '置为有效'){
                s = 1
            }else if(this.srnr == '批量删除'){
                s = 3
            }
            var tid= []
            var id= []
            for (const iterator of this.cwsm.cs) {
                tid.push(iterator.tid)
                id.push(iterator.id)
            }
            console.log(tid,id,s);
            this.$api.ERP.mat_spec.requestmat_specob({
                op_status:Number(s),
                type_ids:tid,
                ids:id
            }).then(res=>{
                console.log(res);
                if(res.code ==1){
                    for (const key in this.cwsm.cs) {
                        this.cwsm.cs[key].jg = '成功'
                    }
                    this.demand()
                    if(this.cwsm.ns.length<1){
                        this.chdefrs()
                    }
                }else if(res.code ==2){
                    for (const key in this.cwsm.cs) {
                        for (const keys in res.data) {
                            if(this.cwsm.cs[key].id == res.data[keys].id){
                                this.cwsm.cs[key].jg = '失败'
                            }
                        }
                    }
                    for (const key in this.cwsm.cs) {
                        if(this.cwsm.cs[key].jg == '---'){
                            this.cwsm.cs[key].jg = '成功'
                        }
                    }
                }else{
                    this.$message.warning(res.msg) 
                }
            })
        },
        // 无效
        noneffective(){
            if(this.multipleSelection.length > 0){
                this.$api.ERP.mat_spec.requestmat_specdisable({ids:this.multipleSelection}).then(res=>{
                    console.log(res);
                    if(res.code ==1){
                        this.demand()
                        this.weik()
                        this.dialogFible= false
                        this.$message({
                            showClose:true,
                            message:"操作成功",
                            type:'success'
                        })
                    }else if(res.code == 2){
                        this.dialogFible=true
                        this.kzsfjy=false
                        this.srnr = '置为无效'
                        this.cwsm.ns = res.data.ns||[]
                        for (const key in res.data.cs) {
                            res.data.cs[key].jg = '---'
                        }
                        this.cwsm.cs = res.data.cs||[]
                    }else{
                        this.$message.warning(res.msg) 
                    }
                })
            }else{
                this.$message.warning("请选择一个进行更改") 
            }
        },
        // 有效
        effective(){
            if(this.multipleSelection.length > 0){
                this.$api.ERP.mat_spec.requestmat_specenable({ids:this.multipleSelection}).then(res=>{
                    console.log(res);
                    if(res.code ==1){
                        this.demand()
                        this.weik()
                        this.dialogFible= false
                        this.$message({
                            showClose:true,
                            message:"操作成功",
                            type:'success'
                        })
                    }else if(res.code == 2){
                        this.dialogFible=true
                        this.kzsfjy=false
                        this.srnr = '置为有效'
                        this.cwsm.ns = res.data.ns||[]
                        for (const key in res.data.cs) {
                            res.data.cs[key].jg = '---'
                        }
                        this.cwsm.cs = res.data.cs||[]
                    }else{
                        this.$message.warning(res.msg) 
                    }
                })
            }else{
                this.$message.warning("请选择一个进行删除") 
            }
        },
        // 删除
        printerdel(){
            if(this.multipleSelection.length > 0){
                this.$api.ERP.mat_spec.requestmat_specdel({ids:this.multipleSelection}).then(res=>{
                    console.log(res);
                    if(res.code ==1){
                        this.demand()
                        this.weik()
                        this.dialogFible= false
                        this.$message({
                            showClose:true,
                            message:"操作成功",
                            type:'success'
                        })
                    }else if(res.code == 2){
                        this.dialogFible=true
                        this.kzsfjy=false
                        this.srnr = '批量删除'
                        this.cwsm.ns = res.data.ns||[]
                        for (const key in res.data.cs) {
                            res.data.cs[key].jg = '---'
                        }
                        this.cwsm.cs = res.data.cs||[]
                    }else{
                        this.$message.warning(res.msg) 
                    }
                })                
            }else{
                this.$message.warning("请选择一个进行删除") 
            }

        },
        // 滚动最大高度
        RollMaxHeight(i){   
            var s = i - 48 - 60 - 55 - 37
            this.MaxHeight = s
            this.MaxNumber = Math.floor(s/37)
            console.log(this.MaxNumber);
            // console.log(i);
        }
    },
    watch:{
        windowHeigh(val) {
            let that = this;
            this.RollMaxHeight(val)
        //   console.log("实时屏幕高度：",val, that.windowHeigh );
        },
        windowWidt (val) {
          let that = this;
        //   console.log("实时屏幕宽度：",val, that.windowWidt );
        },
    }
 
}
</script>
<style>
    .mat_spec{
        width: calc(100% - 40px);
        height: calc(100% - 40px);
        padding:20px 30px;
    } 
    /* 必填 */
    .mat_spec .mandatory{
        color: #D9D9D9 ;
        width: 140px;
        text-align: right;
        line-height: 34px;
    }
    .mat_spec .controlling{
        width: 230px !important;
    }
    .cwts{
        color: #CE4253 ;
        line-height: 34px;
        padding-left: 10px;
    }
    .mat_spec .reqfieldsd{
        font-size: 14px;
        padding-right: 4px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select:none;
        -moz-user-select:none;
        -ms-user-select:none;
        user-select:none;
    }
    /* 表格无数据时展示 */
    
    .mat_spec .tiaodd{
        position: sticky;
        left: 0;
        top: 44px;
        width: 100% !important;
        display: inline-block;
        /* 文字不可选中 */
        -webkit-user-select:none;
        -moz-user-select:none;
        -ms-user-select:none;
        user-select:none;
    }
    .mat_spec .nodata{
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
    }
    .mat_spec .nodata img{
        width: 60px;
        height: 60px; 
    }
    .mat_spec .nodata .hint{
        line-height: 36px;
        font-size: 13px  !important;
    }

    /* 内容 */
    .mat_spec .mat_spec-headline{
        font-size: 30px;
        font-weight: bold;
        color: #D9D9D9;
    }
    .mat_spec .mat_spec-controller{
        /* margin-top: 30px; */
        height: 54px;
        /* width: 1600px; */
        width: 100%;
        background-color: #202026;
        border-top: 1px solid #2c2d36;
        display: flex;
        align-items: center;
    }
    .mat_spec .layouts{
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select:none;
        -moz-user-select:none;
        -ms-user-select:none;
        user-select:none;
    }
    .mat_spec .compatibility{
        display: flex;
        /* align-items: center; */
        margin-bottom: 10px;
    }
    .mat_spec .required{
        width: 60px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select:none;
        -moz-user-select:none;
        -ms-user-select:none;
        user-select:none;
    }
    /* 取消按钮 */
    .mat_spec .el-dialog .el-button--default{
        background-color: #ccc ;
        border: 1px solid #ccc;
        color: #40404e;
    } 

    .mat_spec .el-input .el-input__count .el-input__count-inner{
        background: none;
        color: #D9D9D9;
    }
    .mat_spec .el-input__suffix{
        background-color: #1A1A20;
        color: #D9D9D9;
        right: -45px;
        /* height: 20px; */
        top: 8px;
        /* line-height: 20px; */
        -webkit-user-select:none;
        -moz-user-select:none;
        -ms-user-select:none;
        user-select:none;
    }



    /* 靠右 */
    .mat_spec  .el-dialog{
        background-color: #f9f9f9;
        margin: 0px 0px 0px auto !important;
        height: 100%;
        position: relative;
    } 
    .mat_spec .el-dialog__footer{
        position: absolute;
        width: 100%;
        bottom: 0;
        right: 0;
        display: flex;
        justify-content: center;
    }
    .mat_spec  .el-dialog__body{
        padding:0px 0px 30px 20px ;
        overflow-y: scroll !important;
        /* width: 100%; */
        width: calc(100% - 40px);
        height: calc(100% - 160px);
        max-height: calc(100% - 160px);
        margin: 0;
    }
    .mat_spec .dialogFormVisible .el-dialog{
        width: 720px !important;
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .mat_spec .el-input__inner{
        background-color: rgba(0, 0, 0, 0);
        color: #D9D9D9;
    }
    .mat_spec .el-dialog__header,.mat_spec .el-dialog__footer{
        background-color: #1a1a21;
    }
    .mat_spec .el-dialog__title,.mat_spec .el-dialog__headerbtn .el-dialog__close,.mat_spec .el-form-item__label{
         color: #1a1a21;
    }
    .mat_spec .el-input{
        width: 100%;
    }
    .mat_spec .el-form-item{
        display: flex;
        margin: 0;
    }
    .mat_spec .el-checkbox-group{
        display: flex;
        align-items: flex-end;
        justify-content: left;
    }
    .mat_spec .el-checkbox__input{
        background-color: rgba(0, 0, 0, 0);
    }
    .mat_spec table thead tr th,.mat_spec table tbody tr td{
        height: 40px;
        font-size: 14px;
        
    } 

/* 错误2 */    
    .mat_spec .diagrgeesfelogFor .el-dialog{
        width: 720px;
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }
    .mat_spec .diagrgeesfelogFor .wwent{
        color: #ce4153;
        font-size: 14px;
        margin: 20px 0px 20px 20px;
        display: flex;
        align-items: center;
    }
    .mat_spec .diagrgeesfelogFor .wentlb{
        margin-left: 20px;
        width: 640px;
    }    
    .mat_spec .diagrgeesfelogFor .zhuixiaoi{
        width: 100%;
    }
    .mat_spec .diagrgeesfelogFor .zhuixiaoi .limiting{
        max-height: 280px !important;
        overflow-y: auto !important;
    }
    .mat_spec .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(1),.mat_spec .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(1){
        width: 50px;
    }
    .mat_spec .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(2),.mat_spec .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(2){
        width: 320px;
    }
    .mat_spec .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(3),.mat_spec .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(3){
        width: 200px;
    }
    .mat_spec .diagrgeesfelogFor .danykz .mmodity th:nth-of-type(2),.mat_spec .diagrgeesfelogFor .danykz .drag-list td:nth-of-type(2){
        width: 520px;
    }
    /* 无效颜色 */
    .mat_spec .diagrgeesfelogFor .el-button--primary.is-disabled,.mat_spec .diagrgeesfelogFor .el-button--primary.is-disabled:hover{
        background-color: #1F2846;
        color: #4e505a;
        border-color: #1F2846;
    }
    

/* 仓库列表 */
    .mat_spec .meisfgr{
        width:100%;
        overflow-x: scroll;
    }
    .mat_spec  .zhuixiaoi{
        width:100%;
        border-collapse: collapse;
        color: #D9D9D9 ;   
    }
    .mat_spec .zhuixiaoi .mmodity tr th{
        height: 36px;
        line-height: 36px;
        text-align: left;
        font-size: 14px;
        font-weight:400;
        padding-left: 20px;
    }
    .mat_spec .zhuixiaoi .limiting .drag-list td{
        height: 36px;
        line-height: 36px;
        text-align: left;
        font-size: 14px;
        font-weight:400;
        padding-left: 20px;
    }
    .mat_spec .zhuixiaoi .limiting .drag-list{
        border-top: solid 1px #383943;
        display:block;
        display: flex;
    }
    .mat_spec .zhuixiaoi .mmodity{
        background-color: #2d2e38; 
        width: 100%;
        display:block;
    }
    .mat_spec .zhuixiaoi .mmodity tr{
        display: flex;
    }
    .mat_spec .zhuixiaoi .limiting{
        /* width: calc(100% + 17px);  */
        /* width: 100%;  */
        overflow-y: auto !important;
        max-height: 540px ;
        border-bottom: solid 1px #383943;
        /* width: 100%; */
        display:block;
    }
    .mat_spec .drag-list td:nth-of-type(1),.mat_spec .mmodity th:nth-of-type(1){
        width: 70px;
    }
    .mat_spec .mmodity th:nth-of-type(2), .mat_spec .drag-list td:nth-of-type(2){
        width: 300px;
    }
    .mat_spec .drag-list td:nth-of-type(3),.mat_spec .mmodity th:nth-of-type(3){
        width: 200px;
    }
    .mat_spec .drag-list td:nth-of-type(4),.mat_spec .mmodity th:nth-of-type(4){
        width: 200px;
    }
    .mat_spec .drag-list td:nth-of-type(5),.mat_spec .mmodity th:nth-of-type(5){
        width: 100px;
    }
    .mat_spec .drag-list:nth-of-type(odd) {
        background-color: #f9f9f9 ;
        color: #40404e ;
    }
    .mat_spec .drag-list:nth-of-type(even){
        background-color: #f5f5f5;
        color: #40404e ;
    }    
    /* 表格全选字体颜色 */
    .mat_spec .zhuixiaoi .el-checkbox__label{
        color: #40404e ;
    }
    .mat_spec .zhuixiaoi .mmodity .el-checkbox__label{
        font-size: 12px;
    }

    .drag-list-check {
        /* background: rgba(39, 52, 82, .5) !important; */
    }
</style>

