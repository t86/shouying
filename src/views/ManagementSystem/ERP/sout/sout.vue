<template>
    <div class="sout">
        <div class="sout-rkrq">
            <div class="rkrq">
                <span class="">出库日期：</span>
                <el-radio-group v-model="jindst" class="danxk">
                    <el-radio-button label="1">
                        <img v-show="jindst != 1" src="@/assets/img/date_label_grey.png" alt="">
                        <img v-show="jindst == 1" src="@/assets/img/date_label_selete.png" alt="">
                        近七天
                    </el-radio-button>
                    <el-radio-button label="2">
                        <img v-show="jindst != 2" src="@/assets/img/date_label_grey.png" alt="">
                        <img v-show="jindst == 2" src="@/assets/img/date_label_selete.png" alt="">
                        近1个月
                    </el-radio-button>
                    <el-radio-button label="3">
                        <img v-show="jindst != 3" src="@/assets/img/date_label_grey.png" alt="">
                        <img v-show="jindst == 3" src="@/assets/img/date_label_selete.png" alt="">
                        近3个月
                    </el-radio-button>
                </el-radio-group>
                <el-date-picker
                        v-model="Inbound.date"
                        type="daterange"
                        :editable="false"
                        :unlink-panels="true"
                        @input="adgg"
                        range-separator="至"
                        start-placeholder="开始日期"
                        end-placeholder="结束日期"
                        format="yyyy-MM-dd"
                        value-format="yyyy-MM-dd">
                </el-date-picker>
            </div>
            <div class="rkrq">
                <span>出库类型：</span>
                <el-select v-model="Inbound.type" placeholder="全部" @change="inquirequery" clearable>
                    <el-option label="全部" value=""></el-option>
                    <el-option label="销售出库" :value="11"></el-option>
                    <el-option label="其他出库" :value="17"></el-option>
                    <el-option label="盘亏出库" :value="52"></el-option>
                </el-select>
            </div>
            <div class="rkrq">
                <span>备注：</span>
                <el-input v-model="Inbound.remark" @input="inquirequery" placeholder="请输入备注模糊搜索"></el-input>
            </div>
            <div class="rkrq">
                <!-- <el-button type="primary" @click="inquirequery">查询</el-button> -->
                <el-button type="primary" @click="resetstorage">重置</el-button>
            </div>
        </div>
        <div class="sout-controller">
            <icon-button @click.native="xingh" text="新增" img="btn_add.png" colors="#f5f5f5"></icon-button>
            <characters-button @click.native="compileprinter" colors="#f5f5f5" wz='红冲'></characters-button>
            <characters-button @click.native="noneffective" colors="#f5f5f5" wz='红冲整单'></characters-button>
            <characters-button @click.native="effective" colors="#f5f5f5" wz='类似创建'></characters-button>
        </div>
        <div style="position: relative">
            <div class="zsykd" style="display: inline-block;">
                <table class="zhuixiaoi">
                    <thead class="mmodity">
                    <tr>
                        <th>
                            <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll" @change="handleCheckAllChange">
                                全选
                            </el-checkbox>
                        </th>
                        <th>单号</th>
                        <th>出库类型</th>
                        <th>出库仓库</th>
                        <th>
                            <div class="alignment">出库成本</div>
                        </th>
                        <th>
                            <div class="alignment">出库金额</div>
                        </th>
                        <th>备注</th>
                        <th>出库时间</th>
                        <th>出库操作人</th>
                    </tr>
                    </thead>
                    <tbody class="limiting" ref="systemForm" @scroll="sysHandleScroll()"
                           @mouseover="changeFlag(false)" :style="{'border-bottom':tableData.length<1?'0px':'',
                'width':tableData.length>13?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`
                }">
                    <tr v-for="(item,i) in tableData" :key="item.id" class="drag-list"
                        :class="multipleSelection.includes(item.id)? 'drag-list-check':''">
                        <td>
                            <el-checkbox-group v-model="multipleSelection" @change="handleCheckedCitiesChange">
                                <el-checkbox :disabled="item.hc==2" :label="item.id">{{i+1}}&emsp;&thinsp;</el-checkbox>
                            </el-checkbox-group>
                        </td>
                        <td>
                            <div class="ewdetai" @click="showviewdetails(item.id)">
                                {{item.cd}}
                            </div>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.rt || '-----'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.sn || '-----'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <div class="alignment">{{item.ta}}</div>
                        </td>
                        <td>
                            <div class="alignment">{{item.sa}}</div>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.r || '-----'"></ellipsis-tooltip>
                        </td>
                        <td>{{item.st}}</td>
                        <td>{{item.en}}</td>
                    </tr>
                    </tbody>
                </table>
                <div class="tiaodd" v-if="tableData.length<1">
                    <td class="nodata" :style="{'height':`${MaxHeight}px !important`}">
                        <img :src="img" alt="">
                        <div class="hint">暂无数据</div>
                    </td>
                </div>
            </div>
            <div style="display: inline-block;position: absolute;top: 0;left: 0;z-index: 100;">
                <table class="zhuixiaoi zhuixiaoi_l" style="width: auto;">
                    <thead class="mmodity">
                    <tr>
                        <th>
                            <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll" @change="handleCheckAllChange">
                                全选
                            </el-checkbox>
                        </th>
                        <th>单号</th>
                        <th>出库类型</th>
                        <th>出库仓库</th>
                    </tr>
                    </thead>
                    <tbody class="limiting" ref="externalForm" @scroll="exterHandleScroll()"
                           @mouseover="changeFlag(true)" :style="{'border-bottom':tableData.length<1?'0px':'',
                'width':tableData.length>13?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`
                }">
                    <tr v-for="(item,i) in tableData" :key="item.id" class="drag-list"
                        :class="multipleSelection.includes(item.id)? 'drag-list-check':''">
                        <td>
                            <el-checkbox-group v-model="multipleSelection" @change="handleCheckedCitiesChange">
                                <el-checkbox :disabled="item.hc==2" :label="item.id">{{i+1}}&emsp;&thinsp;</el-checkbox>
                            </el-checkbox-group>
                        </td>
                        <td>
                            <div class="ewdetai" @click="showviewdetails(item.id)">
                                {{item.cd}}
                            </div>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.rt || '-----'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.sn || '-----'"></ellipsis-tooltip>
                        </td>
                    </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <div class="Pagination">
            <el-pagination
                    background
                    layout="prev, pager, next"
                    @current-change="handleCurrentChange"
                    :page-size="10"
                    :total="Inbound.rowcnt">
            </el-pagination>
        </div>


        <!-- 新增出库 -->
        <div v-show="dialogFormVisible" class="dialogFormVisible">
            <el-dialog title="新增出库" :visible.sync="dialogFormVisible" @close="dialogFormVisible = false"
                       :close-on-click-modal="false">
                <el-form label-position="left">
                    <div class="tidsesfe">
                        <div class="compatibility compatibils">
                            <div class="mandatory">
                                <span class="reqfieldsd">*</span>出库仓库：
                            </div>
                            <el-select v-model="ProductLibrary.warehouse" class="controlling" placeholder="请选择仓库"
                                       clearable>
                                <el-option v-for="(each,i) in ProductLibrary.warehousess" :key="i" :label="each.n"
                                           :value="each.id"></el-option>
                            </el-select>
                        </div>
                        <div class="compatibility compatibils">&emsp;&emsp;&emsp;
                            <div class="mandatory">
                                <span class="reqfieldsd">*</span>出库类型：
                            </div>
                            <el-select v-model="ProductLibrary.type" class="controlling" placeholder="请选择类型" clearable>
                                <el-option label="销售出库" :value="11"></el-option>
                                <el-option label="其他出库" :value="17"></el-option>
                            </el-select>
                        </div>
                    </div>
                    <div class="compatibility ">
                        <span class="required"></span>
                        <el-form-item label="备注" prop="printerIP">
                            <label slot="label">备&emsp;&emsp;注：</label>
                            <el-input type="textarea" class="controlling" v-model="ProductLibrary.remark" :rows="3"
                                      placeholder="请输入备注" show-word-limit
                                      :class="form_rule_msg_remark?'error':''" @blur="validator('remark')"/>
                            <div class="cwts">{{form_rule_msg_remark}}</div>
                        </el-form-item>
                    </div>
                </el-form>
                <div class="addmaterial">
                    <div class="rkrq">
                        <icon-button @click.native="appendmaterial" text="添加物料" img="btn_add.png"
                                     colors="#f5f5f5"></icon-button>
                        <icon-button @click.native="batchDeleteSupplies" text="批量删除" img="btn_delete.png" colors="#6B2830"
                                     bjcolors="#491E24"></icon-button>
                        <!-- <el-button type="primary" @click="appendmaterial">添加物料</el-button>
                        <el-button type="primary" @click="batchDeleteSupplies">批量删除</el-button> -->
                    </div>
                    <table class="zhuixiaoi">
                        <thead class="mmodity">
                        <tr>
                            <th>
                                <el-checkbox :indeterminate="isIndeterminateadd" v-model="checkAlladd"
                                             @change="handleCheckAllChangeadd">全选
                                </el-checkbox>
                            </th>
                            <th>物料名称</th>
                            <th>一级分类</th>
                            <th>二级分类</th>
                            <th>单位</th>
                            <th>
                                <div class="alignment">数量</div>
                            </th>
                            <th>
                                <div class="alignment">出库单价</div>
                            </th>
                            <th>
                                <div class="alignment">小计</div>
                            </th>
                        </tr>
                        </thead>
                        <tbody class="limiting" :style="{'border-bottom':supplies.length<1?'0px':''}">
                        <tr v-for="(item,i) in supplies" :key="i" class="drag-list"
                            :class="checkedCitiesadd.includes(item.id)? 'drag-list-check':''">
                            <td>
                                <el-checkbox-group v-model="checkedCitiesadd" @change="handleCheckedCitiesChangeadd">
                                    <el-checkbox :label="item.id">{{i+1}}</el-checkbox>
                                </el-checkbox-group>
                            </td>
                            <td>
                                <ellipsis-tooltip :text="item.n || '-----'"></ellipsis-tooltip>
                            </td>
                            <td>
                                <ellipsis-tooltip :text="item.moc || '-----'"></ellipsis-tooltip>
                            </td>
                            <td>
                                <ellipsis-tooltip :text="item.mtc || '-----'"></ellipsis-tooltip>
                            </td>
                            <td>
                                <ellipsis-tooltip :text="item.un || '-----'"></ellipsis-tooltip>
                            </td>
                            <td>
                                <el-input v-model="item.sl" placeholder="请输出数量" class="Writmiddle"/>
                                <!-- <el-input-number :controls="false" v-model="item.sl" :min="0" :max="item.a" placeholder="请输入数量"></el-input-number> -->
                            </td>
                            <td>

                                <el-input v-model="item.sp" placeholder="请输出单价" class="Writmiddle"/>
                                <!-- <el-input-number :controls="false" v-model="item.sp" :precision="2" placeholder="请输入价格" class="Writmiddle" ></el-input-number> -->
                            </td>
                            <td>
                                <div class="alignment">{{((item.sp*1)*(item.sl*1)) | decimal}}</div>
                            </td>
                        </tr>
                        </tbody>
                    </table>
                    <div class="tiaodd" v-if="supplies.length<1">
                        <td class="nodata">
                            <img :src="img" alt="">
                            <div class="hint">暂无数据</div>
                        </td>
                    </div>
                </div>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="dialogFormVisible = false">取消</el-button>
                    <el-button type="primary" @click="construction">确认</el-button>
                </span>
            </el-dialog>
        </div>
        <!-- 添加物料 -->
        <div class="search" v-show="addprincipal">
            <el-dialog title="添加物料" :visible.sync="addprincipal" @close="addprinddawcipal"
                       :close-on-click-modal="false">
                <el-input v-model="dimvalue" placeholder="请输入物料拼音首字母或名称的关键字" clearable ref="selectsse"
                          class="topwidth"></el-input>
                <div class="materialsoutformation">
                    <div class="information">选择你要出库的商品及数量和出库单价</div>
                    <table class="zhuixiaoi">
                        <thead class="mmodity">
                        <tr>
                            <th>序号</th>
                            <th>物料名称</th>
                            <th>基本单位</th>
                            <th>
                                <div class="alignment">当前库存</div>
                            </th>
                            <th>
                                <div class="alignment">出库价格</div>
                            </th>
                            <th>
                                <div class="alignment">出库数量</div>
                            </th>
                            <th>
                                <div class="alignment">出库小计</div>
                            </th>
                        </tr>
                        </thead>
                        <tbody class="limiting" :style="{'border-bottom':dimoptions.length<1?'0px':'',
                            'width':dimoptions.length>8?'calc(100% + 6px)':'100%'}">
                        <tr v-for="(item,i) in dimoptions" :key="i" class="drag-list"
                            :class="checkedCitiesdim.includes(item.id)? 'drag-list-check':''">
                            <td>
                                <el-checkbox-group v-model="checkedCitiesdim">
                                    <el-checkbox :label="item.id">{{i+1}}</el-checkbox>
                                </el-checkbox-group>
                            </td>
                            <td>
                                <ellipsis-tooltip :text="item.n || '-----'"></ellipsis-tooltip>
                            </td>
                            <td>
                                <ellipsis-tooltip :text="item.un || '-----'"></ellipsis-tooltip>
                            </td>
                            <td>
                                <div class="alignment">{{item.c}}</div>
                            </td>
                            <td>
                                <el-input v-model="item.sp" placeholder="请输入价格" class="Writmiddle"/>
                            </td>
                            <td>
                                <el-input v-model="item.sl" placeholder="请输入数量" class="Writmiddle"/>
                            </td>
                            <td>
                                <div class="alignment">{{((item.sp*1||0)*(item.sl*1||0)) | decimal}}</div>
                            </td>
                        </tr>
                        </tbody>
                    </table>
                    <div class="tiaodd" v-if="dimoptions.length<1">
                        <td class="nodata">
                            <img :src="img" alt="">
                            <div class="hint">暂无数据</div>
                        </td>
                    </div>
                </div>
                <div class="materialsoutformation">
                    <div class="information">已选待出库物料：</div>
                    <div class="xzrr">
                        <el-tag v-for="tag in savedata" :key="tag.id" closable @close="handleClose(tag)"
                                :disable-transitions="true">
                            {{tag.n}}&emsp;{{tag.un}}×{{tag.sl}}
                        </el-tag>
                    </div>
                </div>
                <span slot="footer" class="dialog-footer">
                  <el-button @click="addprinddawcipal">取消</el-button>
                  <el-button type="primary" @click="AddFile">添加</el-button>
                </span>
            </el-dialog>
        </div>
        <!-- 查看详情 -->
        <div v-show="cfdetails" class="viewdetailscls">
            <el-dialog title="查看详情" :visible.sync="cfdetails" @close="cfdetails = false" :close-on-click-modal="false">
                <div ref="print" id="print">
                    <div class="printsout">
                        <div class="monad">其他出库单</div>
                        <div class="form m-t-6" style="background: #eee;border-radius:10px">
                          <div class="row" layout="row" layout-align="start center">
                            <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                              <div class="label" style="width:150px;text-align:right">单号：</div>
                              <div class="value" style="width:150px">{{viewdetails.code}}</div>
                            </div>
                            <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                              <div class="label" style="width:150px;text-align:right">出库仓库：</div>
                              <div class="value" style="width:150px">{{viewdetails.store_name}}</div>
                            </div>
                            <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                              <div class="label" style="width:150px;text-align:right">出库类型：</div>
                              <div class="value" style="width:150px">{{viewdetails.record_type}}</div>
                            </div>
                          </div>
                          <div class="row" layout="row" layout-align="start center">
                            <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                              <div class="label" style="width:150px;text-align:right">出库时间：</div>
                              <div class="value" style="width:150px">{{viewdetails.store_time}}</div>
                            </div>
                            <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                              <div class="label" style="width:150px;text-align:right">出库操作员名称：</div>
                              <div class="value" style="width:150px">{{viewdetails.oper_emp_name}}</div>
                            </div>
                            <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                              <div class="label" style="width:150px;text-align:right">出库单总成本：</div>
                              <div class="value" style="width:150px">{{viewdetails.total_amt}}</div>
                            </div>
                          </div>
                          <div class="row" layout="row" layout-align="start center">
                            <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                              <div class="label" style="width:150px;text-align:right">出库单总出库金额：</div>
                              <div class="value" style="width:150px">{{viewdetails.sell_total_amt}}</div>
                            </div>
                            <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                              <div class="label" style="width:150px;text-align:right">备注：</div>
                              <div class="value" style="width:150px">{{viewdetails.remark || '---'}}</div>
                            </div>
                          </div>

                        </div>
                        <!-- <el-form label-position="left">
                            <div class="tidsesfe">
                                <div class="compatibility">
                                    <div class="mandatory" style="">
                                        <span class="reqfieldsd"></span>单号：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.code}}</div>
                                </div>
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>出库仓库：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.store_name}}</div>
                                </div>
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>出库类型：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.record_type}}</div>
                                </div>
                            </div>
                            <div class="tidsesfe">
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>出库时间：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.store_time}}</div>
                                </div>
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>出库操作员名称：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.oper_emp_name}}</div>
                                </div>
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>出库单总成本：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.total_amt}}</div>
                                </div>
                            </div>
                            <div class="tidsesfe">
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>出库单总出库金额：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.sell_total_amt}}</div>
                                </div>
                            </div>
                            <div class="tidsesfe">
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>备注：
                                    </div>
                                    <div class="materialnr gaib">{{viewdetails.remark || "----"}}</div>
                                </div>
                            </div>
                        </el-form> -->
                        <div class="mldw m-t-8 m-b-3" v-if="viewdetails.dtls != null">明细单列表</div>
                        <div v-if="viewdetails.dtls != null" class="addmaterial">
                            <table class="zhuixiaoi" border style="width:auto">
                                <thead class="mmodity">
                                <tr>
                                    <th>序号</th>
                                    <th>物料名称</th>
                                    <th>一级分类</th>
                                    <th>二级分类</th>
                                    <th>出库单位</th>
                                    <th>出库数量</th>
                                    <th>出库单价</th>
                                    <th>出库成本金额</th>
                                    <th>出库小计</th>
                                </tr>
                                </thead>
                                <tbody class="limiting">
                                <tr v-for="(item,i) in viewdetails.dtls" :key="i" class="drag-list">
                                    <td>{{i+1}}</td>
                                    <td>{{item.n || '-----'}}</td>
                                    <td>{{item.moc || '-----'}}</td>
                                    <td>{{item.mtc || '-----'}}</td>
                                    <td>{{item.un || '-----'}}</td>
                                    <td>{{item.c}}</td>
                                    <td>{{(item.sa/item.c).toFixed(2)}}</td>
                                    <td>{{item.a}}</td>
                                    <td>{{item.sa}}</td>
                                </tr>
                                </tbody>
                            </table>
                        </div>
                        <div class="mldw" v-if="viewdetails.hc_dtls != null"
                             style="margin-top: 16px;margin-bottom: 20px;">红冲记录
                        </div>
                        <div v-if="viewdetails.hc_dtls != null" class="addmassrial">
                            <table class="zhuixiaoi" border style="width:auto">
                                <thead class="mmodity">
                                <tr>
                                    <th>序号</th>
                                    <th>物料名称</th>
                                    <th>红冲操作员名称</th>
                                    <th>红冲数量</th>
                                    <th>红冲成本小计</th>
                                    <th>红冲单位名称</th>
                                    <th>红冲前数量</th>
                                    <th>红冲后数量</th>
                                    <th>红冲操作时间</th>
                                    <th>红冲小计</th>
                                </tr>
                                </thead>
                                <tbody class="limiting">
                                <tr v-for="(item,i) in viewdetails.hc_dtls" :key="i" class="drag-list">
                                    <td>{{i+1}}</td>
                                    <td>{{item.n || '-----'}}</td>
                                    <td>{{item.oen}}</td>
                                    <td>{{item.c}}</td>
                                    <td>{{item.a}}</td>
                                    <td>{{item.un || '-----'}}</td>
                                    <td>{{item.bc}}</td>
                                    <td>{{item.ac}}</td>
                                    <td>{{item.ot}}</td>
                                    <td>{{item.sa}}</td>
                                </tr>
                                </tbody>
                            </table>
                        </div>

                        <div class="signature show">
                            <div>
                                <span>总金额：{{viewdzj}}元</span>
                            </div>
                        </div>
                        <div class="signature show">
                            <div>
                                <span>签收人：</span>
                                <div class="xian"></div>
                            </div>
                            <div>
                                <span>送货人：</span>
                                <div class="xian"></div>
                            </div>
                        </div>
                    </div>
                </div>

                <span slot="footer" class="dialog-footer">
                    <el-button @click="cfdetails = false">关闭</el-button>
                    <el-button type="primary" v-show="viewdetails.status == '已完成'" v-print="print">打印</el-button>
                    <el-button type="primary" @click="effective">类似创建</el-button>
                    <el-button type="primary" v-show="viewdetails.status == '已完成'"
                               @click="compileprinter">红冲</el-button>
                    <el-button type="primary" v-show="viewdetails.status == '已完成'" @click="noneffective">反审核</el-button>
                </span>
            </el-dialog>
        </div>
        <!-- 红冲 -->
        <div v-show="Reddashed" class="hcwdetailscls" v-if="hcsl[0]">
            <el-dialog title="红冲" :visible.sync="Reddashed" @close="Reddashed = false" :close-on-click-modal="false">
                <el-form label-position="left">
                    <div class="tidsesfe">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd"></span>出库单号：
                            </div>
                            <div class="materialnr controlling">{{viewdetails.code}}</div>
                        </div>
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd"></span>仓库：
                            </div>
                            <div class="materialnr controlling">{{viewdetails.store_name}}</div>
                        </div>
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd"></span>类型：
                            </div>
                            <div class="materialnr controlling">{{viewdetails.record_type}}</div>
                        </div>
                    </div>
                    <div class="tidsesfe">
                        <div class="compatibil">
                            <div class="compatibility">
                                <div class="mandatory">
                                    <span class="reqfieldsd"></span>出库时间：
                                </div>
                                <div class="materialnr controlling">{{viewdetails.store_time}}</div>
                            </div>
                        </div>
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd"></span>出库操作员名称：
                            </div>
                            <div class="materialnr controlling">{{viewdetails.oper_emp_name}}</div>
                        </div>
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd"></span>出库单总成本：
                            </div>
                            <div class="materialnr controlling">{{viewdetails.total_amt}}</div>
                        </div>
                    </div>
                    <div class="tidsesfe">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd"></span>出库单出库金额：
                            </div>
                            <div class="materialnr controlling">{{viewdetails.sell_total_amt}}</div>
                        </div>
                    </div>
                    <div class="tidsesfe">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd"></span>备注：
                            </div>
                            <div class="materialnr gaib">{{viewdetails.remark || '----'}}</div>
                        </div>
                    </div>
                </el-form>
                <div class="addmaterial">
                    <table class="zhuixiaoi">
                        <thead class="mmodity">
                        <tr>
                            <th>序号</th>
                            <th>物料名称</th>
                            <th>一级分类</th>
                            <th>二级分类</th>
                            <th>出库单位</th>
                            <th>
                                <div class="alignment">红冲前数量</div>
                            </th>
                            <th>
                                <div class="alignment">红冲数量</div>
                            </th>
                            <th>
                                <div class="alignment">红冲后数量</div>
                            </th>
                            <th>
                                <div class="alignment">红冲成本小计</div>
                            </th>
                            <th>
                                <div class="alignment">红冲小计</div>
                            </th>
                        </tr>
                        </thead>
                        <tbody class="limiting">
                        <tr v-for="(item,i) in viewdetails.dtls" :key="i" class="drag-list">
                            <td>{{i+1}}</td>
                            <td>
                                <ellipsis-tooltip :text="item.n || '-----'"></ellipsis-tooltip>
                            </td>
                            <td>
                                <ellipsis-tooltip :text="item.moc || '-----'"></ellipsis-tooltip>
                            </td>
                            <td>
                                <ellipsis-tooltip :text="item.mtc || '-----'"></ellipsis-tooltip>
                            </td>
                            <td>
                                <ellipsis-tooltip :text="item.un || '-----'"></ellipsis-tooltip>
                            </td>
                            <td>
                                <div class="alignment">{{item.c}}</div>
                            </td>
                            <td>
                                <el-input v-model="hcsl[i].sl" @input="hcsl[i].sl = hcsl[i].sl > item.c ? item.c : hcsl[i].sl" placeholder="请输入数量" class="Writmiddle" ref="selectsse"/>
                            </td>
                            <td>
                                <div class="alignment">{{item.c - hcsl[i].sl}}</div>
                            </td>
                            <td>
                                <div class="alignment">{{((item.a/item.c)*hcsl[i].sl).toFixed(2)}}</div>
                            </td>
                            <td>
                                <div class="alignment">{{((item.sa/item.c)*hcsl[i].sl).toFixed(2)}}</div>
                            </td>
                        </tr>
                        </tbody>
                    </table>
                </div>
                <span slot="footer" class="dialog-footer">
                  <el-button @click="Reddashed = false">取消</el-button>
                  <el-button type="primary" @click="hcaffirmReddashed">确认</el-button>
                </span>
            </el-dialog>
        </div>

    </div>
</template>
<script>
import img from '../../../../assets/img/wu.png'
import EllipsisTooltip from '@/components/EllipsisTooltip.vue'//根据路径导入组件
import IconButton from '@/components/IconButton.vue'//根据路径导入组件
import CharactersButton from '@/components/CharactersButton.vue'//根据路径导入组件
export default {
  data(){
    return {
      img: img,
      Inbound: {
        date: [],//日期
        type: '',//类型
        pagenum: 1,//第几页
        pagecnt: 1,//总页数
        rowcnt: 1,//总行数
        jlines: 5,//每页多少行
        remark: '',//备注
      },//出库
      jindst: '1',//近多少天
      tableData: [],// 读取管理列表
      dialogFormVisible: false,//控制新建出库是否显示
      ProductLibrary: {
        warehousess: [],//出库仓库列表
        warehouse: '',//出库仓库
        type: '',// 出库类型
        remark: '',//备注
      },//出库
      multipleSelection: [],// 选中的内容
      isIndeterminate: false,// 出库选择一部分
      checkAll: false,//出库全选
      addprincipal: false,//控制添加物料是否显示

      // checkedCitiesdim: [],//物料已选择内容

      checkAlladd: false,//物料全部选中触发
      checkedCitiesadd: [],//物料已选择内容
      isIndeterminateadd: false,//物料全选或者全不选
      viewdetails: {},//查看详情内容
      cfdetails: false,// 控制查看详情显示与否
      Reddashed: false,// 控制红冲显示与否
      hcsl: [],//红冲内容

      viewdzj: 0,//总金额

      supplies: [],//已添加的物料
      savedata: [],//添加过数量的数据
      sdadgr: false,
      dimvalue: '', // 查询选中的
      dimoptions: [],// 模糊查询列表
      checkedCitiesdim: [],//物料已选择内容

      print: {
        id: 'print',
        popTitle: '其他出库单', // 打印配置页上方标题
        // extraHead: '调拨入库单',
      },
      windowWidt: document.documentElement.clientWidth,  //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight,   //实时屏幕高度
      MaxHeight: 0,//滚动高度
      MaxNumber: 0,//最大个数

      form_rules: ["remark"],
      form_rule_msg_remark: "",

      flag: false
    }
  },
  mounted(){
    this.daterq()
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
  filters: {
    decimal(v){
      // console.log(v);
      return v.toFixed(2)
    }
  },
  components: {
    EllipsisTooltip,
    IconButton,
    CharactersButton
  },
  computed: {},
  methods: {
    //滚动条监听
    changeFlag(flag) {
      this.flag = flag
    },
    // 左右滚动条滚动同步
    sysHandleScroll() {
      if (!this.flag) {
        this.$refs.externalForm.scrollTop = this.$refs.systemForm.scrollTop
      }
    },
    exterHandleScroll() {
      if (this.flag) {
        this.$refs.systemForm.scrollTop = this.$refs.externalForm.scrollTop
      }
    },
    // form表单检测
    validator(val){
      switch (val) {
        case "remark":
          if (this.$overall.character(this.ProductLibrary.remark) > 280) {
            this.form_rule_msg_remark = '输入文字长度超过140'
          } else {
            this.form_rule_msg_remark = ''
          }
          break
      }
    },
    // 滚动最大高度
    RollMaxHeight(i){
      var g = document.getElementsByClassName("sout-rkrq")[0].clientHeight;
      var s = i - 48 - 60 - 55 - 40 - 50 - g;
      this.MaxHeight = s
      this.MaxNumber = Math.floor(s / 37)
      console.log(this.MaxNumber);
      // console.log(i);
    },
    // 打印
    Print(){
      myPrint(this.$refs.print);
      function myPrint(obj) {
        newWindow.print();
      }
    },
    //获取焦点
    edit(){
      this.$nextTick(() => {  //次要代码
        this.$refs.selectsse.focus();
        console.log(this.$refs.selectsse);
      })
    },
    // 使用自定义日期后取消单选框选择的
    adgg(i){
      console.log(i);
      this.jindst = ''
      this.demand()
    },
    // 日期
    daterq(){
      var now = new Date()
      var year = now.getFullYear()//年
      var month = (now.getMonth() + 1).toString().padStart(2, '0')//月
      var date = now.getDate().toString().padStart(2, '0');//日
      // var dangy = new Date(year,month,0).getDate()//当月有多少天
      // this.Inbound.date = [`${year}-${month}-01`,`${year}-${month}-${dangy}`]
      // 7天
      var now7 = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
      var year7 = now7.getFullYear()//年
      var month7 = (now7.getMonth() + 1).toString().padStart(2, '0')//月
      var date7 = now7.getDate().toString().padStart(2, '0');//日
      this.Inbound.date = [`${year7}-${month7}-${date7}`, `${year}-${month}-${date}`]
    },
    // 获取管理列表内容
    demand(){
      // console.log(this.Inbound.type);
      this.$api.ERP.sout.requestsoutlist({
        page_num: this.Inbound.pagenum,
        page_size: 10,
        record_type: Number(this.Inbound.type),
        begin_day: this.Inbound.date[0],
        end_day: this.Inbound.date[1],
        remark: this.Inbound.remark
      }).then(res => {
        console.log(res);
        if (res.code == 1) {
          this.tableData = res.data.datas || []
          this.Inbound.pagecnt = res.data.page_cnt
          this.Inbound.rowcnt = res.data.row_cnt
          this.Inbound.pagenum = res.data.page_num
          this.multipleSelection = []
          this.isIndeterminate = false
          this.checkAll = false
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 选择全选或取消
    handleCheckAllChange(val) {
      // console.log(this.tableData);
      // console.log(val);
      if (val) {
        // console.log(this.tableData);
        this.multipleSelection = []
        for (const key in this.tableData) {
          this.multipleSelection.push(this.tableData[key].id)
        }
      } else {
        this.multipleSelection = []
      }
      this.isIndeterminate = false;
    },
    // 控制单个选中
    handleCheckedCitiesChange(value) {
      // console.log(value);
      let checkedCount = value.length;
      this.checkAll = checkedCount === this.tableData.length;
      this.isIndeterminate = checkedCount > 0 && checkedCount < this.tableData.length;
      // console.log(this.checkedCities);
    },
    // 当前是多少页
    handleCurrentChange(val) {
      // console.log(`当前页: ${val}`);
      this.Inbound.pagenum = val
      this.demand()
    },
    // 查询
    inquirequery(){
      this.demand()
    },
    // 重置
    resetstorage(){
      this.Inbound.date = []
      this.Inbound.type = ''
      this.Inbound.pagenum = 1
      this.Inbound.pagecnt = 1
      this.Inbound.rowcnt = 1
      this.Inbound.remark = ''
      this.tableData = []
      this.jindst = '1'
      this.daterq()
      this.demand()
    },
    // 点开新增出库
    xingh(){
      this.form_rule_msg_remark = '';
      this.dialogFormVisible = true
      this.ProductLibrary.warehouse = ''
      this.ProductLibrary.type = ''
      this.ProductLibrary.remark = ''
      this.supplies = []
      this.checkAlladd = false
      this.checkedCitiesadd = []
      this.isIndeterminateadd = false
      this.$api.ERP.sout.requestsoutstore_items().then(res => {
        // console.log(res);
        this.ProductLibrary.warehousess = res.data
      })
    },
    // 添加物料
    appendmaterial(){
      // console.log(this.ProductLibrary.warehouse);
      if (this.ProductLibrary.warehouse) {
        // if(this.ProductLibrary.warehouse && this.ProductLibrary.type){
        this.addprincipal = true
        this.dimvalue = ''

        this.remoteMethod('')
        this.sdadgr = true
        this.checkedCitiesdim = []
        this.edit()

        // this.supplies
      } else {
        this.$message.warning("请先选择出库仓库和出库类型再选择添加物料")
      }
    },
    // 关闭新添物料
    addprinddawcipal(){
      this.addprincipal = false
      this.sdadgr = true
    },
    //模糊搜索获取焦点
    edit(){
      this.$nextTick(() => {  //次要代码
        this.$refs.selectsse.focus();
        //   console.log(this.$refs.selectsse);
      })
    },
    // 根据输出的内容模糊查找
    remoteMethod(queryString) {
      if (this.sdadgr) {
        if (queryString == '') {
          this.dimoptions = []
          this.savedata = []
        }
      }
      // console.log(query);
      this.$api.ERP.sout.requestsoutmat_items({
        store_id: this.ProductLibrary.warehouse,
        name: queryString,
        page_num: 1,
        page_size: 9999999,
      }).then(res => {
        console.log(res.data);

        // console.log(this.savedata);
        // console.log(this.dimoptions);
        for (const key in res.data || []) {
          for (const ke in this.savedata) {
            // console.log(this.savedata[ke].sl);
            if (this.savedata[ke].sl) {
              if (res.data[key].id == this.savedata[ke].id) {
                res.data[key].sl = this.savedata[ke].sl
              }
            }
          }
          for (const ke in this.supplies) {
            if (this.supplies[ke].sl) {
              // str.split(" ")
              if (res.data[key].id == this.supplies[ke].id) {
                // console.log( res.data[key].a , this.supplies[ke].sl);
                res.data[key].c = res.data[key].c - this.supplies[ke].sl
              }
            }
          }
        }
        console.log(this.supplies);
        // console.log(res.data);
        this.dimoptions = res.data || []
        // this.checkedCitiesdim = []
        // console.log(this.checkedCitiesdim);
        // console.log(res.data);

        // cb(results);
        // this.loading = false;
        if (this.dimoptions.length == 0) {
          this.$message.warning("出库仓库没有此物料")
        }
      })
    },
    // 删除选中物料
    handleClose(tag) {
      // console.log(tag.id);
      for (const key in this.savedata) {
        if (this.savedata[key].id == tag.id) {
          this.savedata.splice(key, 1)
        }
      }
      for (const key in this.checkedCitiesdim) {
        if (this.checkedCitiesdim[key] == tag.id) {
          this.checkedCitiesdim.splice(key, 1)
        }
      }
    },
    // 物料添加到出库
    AddFile(){
      // console.log(this.dimoptions);
      // console.log(this.savedata);
      // console.log(this.checkedCitiesdim);
      var s = []
      for (const key in this.savedata) {
        for (const ke in this.checkedCitiesdim) {
          if (this.savedata[key].id == this.checkedCitiesdim[ke]) {
            // console.log(this.savedata[key].id,this.savedata[key].sp);
            this.savedata[key].id = this.savedata[key].id
            s.push(this.savedata[key])
          }
        }
      }
      console.log(s);
      var jxs = false
      if (s.length == 0) {
        jxs = false
        this.$message.warning("请勾选一个物料并出库数量不能为空或零")
      }
      for (const iterator of s) {
        // console.log((iterator.sl!==Infinity)&&!isNaN(iterator.sl)&&(iterator.sp!==Infinity)&&!isNaN(iterator.sp));
        // console.log((typeof(iterator.sl)==="number")&&(iterator.sl!==Infinity)&&!isNaN(iterator.sl)&&(typeof(iterator.sp)==="number")&&(iterator.sp!==Infinity)&&!isNaN(iterator.sp));
        if ((iterator.sl !== Infinity) && !isNaN(iterator.sl) && (iterator.sp !== Infinity) && !isNaN(iterator.sp)) {
          jxs = true
        } else {
          jxs = false
          this.$message.warning("勾选的物料出库价格和出库数量不能为空或零")
          return;
        }
      }

      if (jxs) {
        // console.log(s);
        var q = false
        var w = JSON.parse(JSON.stringify(s));
        var arr = []
        console.log(123);
        for (const key in this.supplies) {
          for (const i in s) {
            // console.log(this.supplies[key].id, s[i].id);
            if (this.supplies[key].id == s[i].id) {
              // w.splice(i,1)
              if (this.supplies[key].sp == s[i].sp) {
                arr.push(Number(i))
                this.supplies[key].sl = Number(s[i].sl) + Number(this.supplies[key].sl)
              }
              //     console.log(this.supplies[key]);
              //     console.log(s[i]);
              //     // this.supplies.push(s[i])

              // }

            } else {
              q = q || false
            }
          }
        }
        var max;
        for (var i = 0; i < arr.length; i++) {
          for (var j = i; j < arr.length; j++) {
            if (arr[i] < arr[j]) {
              max = arr[j];
              arr[j] = arr[i];
              arr[i] = max;
            }
          }
        }
        for (const i of arr) {
          w.splice(i, 1)
        }
        console.log(w);
        if (!q) {
          // console.log(w);
          for (const iterator of w) {
            this.supplies.push(iterator)
          }
        }
        console.log(this.supplies);
        // this.supplies = s
        this.addprincipal = false
        // this.$message({showClose:true,message:"添加成功",type:'success'})
      }
    },
    // 批量删除物料
    batchDeleteSupplies(){
      if (this.checkedCitiesadd.length == 0) {
        this.$message.warning('请选择一个在进行删除')
      } else {
        var s = []
        for (const i in this.supplies) {
          // console.log(this.supplies[i].id);
          for (const j in this.checkedCitiesadd) {
            if (this.supplies[i].id == this.checkedCitiesadd[j]) {
              s.push(i)
            }
          }
        }
        for (const i of s.reverse()) {
          this.supplies.splice(i, 1)
        }
        this.checkedCitiesadd = []
        this.checkAlladd = false
        this.isIndeterminateadd = false
      }
    },
    // 选择全选或取消
    handleCheckAllChangeadd(val) {
      if (val) {
        // console.log(this.tableData);
        this.checkedCitiesadd = []
        for (const key in this.supplies) {
          this.checkedCitiesadd.push(this.supplies[key].id)
        }
      } else {
        this.checkedCitiesadd = []
      }
      this.isIndeterminateadd = false;
    },
    // 控制单个选中
    handleCheckedCitiesChangeadd(value) {
      // console.log(value);
      let checkedCount = value.length;
      this.checkAlladd = checkedCount === this.supplies.length;
      this.isIndeterminateadd = checkedCount > 0 && checkedCount < this.supplies.length;
      // console.log(this.checkedCities);
    },
    // 创建出库
    construction(){
      this.form_rules.map(item => this.validator(item));
      if (this.form_rule_msg_remark) return;
      if (this.ProductLibrary.warehouse == '' || this.ProductLibrary.type == '') {
        this.$message.warning('必选框不能为空')
      } else {
        var s = {
          ids: [],
          counts: [],
          amt: [],
        }
        for (const iterator of this.supplies) {
          s.ids.push(iterator.id)
          s.counts.push(Number(iterator.sl))
          s.amt.push(iterator.sp + '')
        }
        // return console.log(111, s);
        this.$api.ERP.sout.requestsoutnew({
          store_id: this.ProductLibrary.warehouse,
          record_type: this.ProductLibrary.type,
          remark: this.ProductLibrary.remark,
          mat_ids: s.ids,
          cnts: s.counts,
          amts: s.amt,
        }).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.$message({
              showClose: true,
              message: "操作成功",
              type: 'success'
            })
            this.dialogFormVisible = false
            this.demand()
          } else {
            this.$message.warning(res.msg)
          }
        })
      }
    },
    // 反审核其他出库单
    noneffective(){
      this.cfdetails = false
      console.log(this.multipleSelection);
      if (this.multipleSelection.length == 1) {
        this.$api.ERP.sout.requestsoutcs({id: this.multipleSelection[0]}).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.demand()
            this.$message({
              showClose: true,
              message: "操作成功",
              type: 'success'
            })
          } else {
            this.$message.warning(res.msg)
          }
        })
      } else {
        this.$message.warning("请选择一个进行操作")
      }

    },
    // 读取其他出库单详情, 用于信息展示
    showviewdetails(id){
      this.multipleSelection = [id]
      this.isIndeterminate = true
      console.log(id);
      this.$api.ERP.sout.requestsoutget_f_view({id: id}).then(res => {
        console.log(res);
        this.viewdetails = res.data
        this.cfdetails = true
        for (const key in this.viewdetails.dtls) {
            this.viewdzj += Number(this.viewdetails.dtls[key].sa * 1)
        }
      })
    },
    // 读取其他出库单详情, 用于红冲
    compileprinter(){
      this.cfdetails = false
      console.log(this.multipleSelection);
      if (this.multipleSelection.length == 1) {
        this.$api.ERP.sout.requestsoutget_f_hc({id: this.multipleSelection[0]}).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.viewdetails = res.data
            this.Reddashed = true
            this.hcsl = []
            for (const key in res.data.dtls) {
              this.hcsl.push({
                sl: '',
                id: res.data.dtls[key].id
              })
            }
          } else {
            this.$message.warning(res.msg)
          }
        })
      } else {
        this.$message({
          message: '请选择一个进行编辑',
          type: 'warning',
        })
      }
    },
    // 红冲确认出库
    hcaffirmReddashed(){
      console.log(this.hcsl);
      var id = []
      var sl = []
      for (const key in this.hcsl) {
        if (this.hcsl[key].sl != 0) {
          id.push(this.hcsl[key].id)
          sl.push(Number(this.hcsl[key].sl))
        }
      }
      console.log(id, sl);
      this.$api.ERP.sout.requestsouthc({
        dtl_ids: id,
        cnts: sl
      }).then(res => {
        if (res.code == 1) {
          this.demand()
          this.Reddashed = false
          this.$message({showClose: true, message: "操作成功", type: 'success'})
        } else {
          this.$message.warning(res.msg)
        }
        console.log(res);
      })
    },
    // 类似创建
    effective(){
      this.cfdetails = false
      // console.log(this.multipleSelection);
      if (this.multipleSelection.length == 1) {
        this.$api.ERP.sout.requestsoutget_f_copy({id: this.multipleSelection[0]}).then(res => {
          console.log(res);
          this.ProductLibrary = {
            warehousess: res.data.stores,
            warehouse: res.data.store_id,
            type: res.data.record_type,
            remark: res.data.remark,
          }
          this.supplies = []
          for (const key in res.data.dtls) {
            this.supplies.push({
              id: res.data.dtls[key].id,
              n: res.data.dtls[key].n,
              moc: res.data.dtls[key].moc,
              mtc: res.data.dtls[key].mtc,
              ui: res.data.dtls[key].ui,
              un: res.data.dtls[key].un,
              sl: res.data.dtls[key].c,
              sp: res.data.dtls[key].sa,
            })
          }
          this.multipleSelection = []
          this.isIndeterminate = false
          this.checkAll = false
          this.dialogFormVisible = true
        })
      } else {
        this.$message.warning("请选择一个进行操作")
      }
    },

  },
  computed: {
    dimoptio(){
      return JSON.parse(JSON.stringify(this.dimoptions))
    },
    checkedCities(){
      return JSON.parse(JSON.stringify(this.checkedCitiesdim))
    },
    supp(){
      return JSON.parse(JSON.stringify(this.supplies))
    },
    hcsls(){
      return JSON.parse(JSON.stringify(this.hcsl || {}))
    },
  },
  watch: {
    windowHeigh(val) {
      let that = this;
      this.RollMaxHeight(val)
      //   console.log("实时屏幕高度：",val, that.windowHeigh );
    },
    windowWidt (val) {
      let that = this;
      this.RollMaxHeight(that.windowHeigh)
      //   console.log("实时屏幕宽度：",val, that.windowWidt );
    },
    // 设置日期
    jindst: {
      deep: true,
      handler: function (after, before) {
        // console.log(after);
        var now = new Date()
        var year = now.getFullYear()//年
        var month = (now.getMonth() + 1).toString().padStart(2, '0')//月
        var date = now.getDate().toString().padStart(2, '0');//日
        // console.log(now.getTime());
        if (after == 1) {// 7天
          this.daterq()
          this.demand()
        } else if (after == 2) {//一个月
          // console.log(now.setMonth(now.getMonth()-1));
          now.setMonth(now.getMonth() - 1)
          var now1 = new Date(now.setMonth(now.getMonth() - 1 + 1))
          var year1 = now1.getFullYear()//年
          var month1 = (now1.getMonth() + 1).toString().padStart(2, '0')//月
          var date1 = now1.getDate().toString().padStart(2, '0');//日
          this.Inbound.date = [`${year1}-${month1}-${date1}`, `${year}-${month}-${date}`]
          this.demand()
        } else if (after == 3) {//3个月
          // console.log(now.setMonth(now.getMonth()-3));
          now.setMonth(now.getMonth() - 3)
          var now3 = new Date(now.setMonth(now.getMonth() - 1 + 1))
          var year3 = now3.getFullYear()//年
          var month3 = (now3.getMonth() + 1).toString().padStart(2, '0')//月
          var date3 = now3.getDate().toString().padStart(2, '0');//日
          this.Inbound.date = [`${year3}-${month3}-${date3}`, `${year}-${month}-${date}`]
          this.demand()
        }
      }
    },
    // 只让输入数字  限制小数点后有两位就不能输入了
    dimoptio: {
      deep: true,
      handler: function (after, before) {
        // this.checkedCitiesdim = []
        // console.log(after);
        for (const key in after) {
          // 只让输入数字  限制小数点后有两位就不能输入了
          if (after[key].sp) {
            var reg = /^[0-9]+(\.[0-9]{0,2})?$/
            if (!reg.test(after[key].sp)) {
              this.dimoptions[key].sp = before[key].sp
            }
            // console.log(this.savedata);
            // console.log(after[key].sp);
            for (const ke in this.savedata) {
              // console.log();
              if (this.savedata[ke].id == after[key].id) {
                this.savedata[ke].sp = after[key].sp
              }

            }
          }
          // console.log(after[key].sl != undefined , after[key].sl != '0',after[key].sl != '');
          if (after[key].sl != undefined && after[key].sl != '0' && after[key].sl != '') {
            var re = /^[0-9]*$/g
            var w = JSON.parse(JSON.stringify(this.checkedCitiesdim));
            if (after[key].sl != '' || after[key].sl != undefined) {
              var s = false
              for (const ke in this.checkedCitiesdim) {
                // console.log(this.checkedCitiesdim[ke] ,after[key].id , "+++++" ,this.checkedCitiesdim[ke] ==after[key].id);
                if (this.checkedCitiesdim[ke] == after[key].id) {
                  s = true || s
                } else {
                  s = false || s
                }
              }

              if (after[key].sl == before[key].sl) {
                this.checkedCitiesdim = w
              } else {
                if (!s) {
                  this.checkedCitiesdim.push(after[key].id)
                }
              }


            }
            if (before[key]) {
              if (after[key].sl != before[key].sl || '') {
                if (re.test(after[key].sl)) {
                  if (after[key].sl > after[key].c) {
                    this.dimoptions[key].sl = after[key].c + ''
                  }
                } else {
                  this.dimoptions[key].sl = (before[key].sl || '') + ''
                }
              }
              // console.log(after[key].sl !=  before[key].sl);
              // console.log(this.savedata);
              // 判断哪个物料的数量发生变化，选中里面有的数量替换，没有添加
              if (after[key].sl != before[key].sl) {
                // console.log(key);
                var s = 0
                for (const ke in this.savedata) {
                  if (this.savedata[ke]) {
                    // console.log(after[key].id == this.savedata[ke].id);
                    if (after[key].id == this.savedata[ke].id) {
                      // console.log(ke);
                      this.savedata[ke].sl = after[key].sl
                    } else {
                      s++
                    }
                  }
                }
                if (s == this.savedata.length) {
                  if (this.savedata.length == 0) {
                    this.savedata.push(after[key])
                  } else {
                    var s = false
                    for (const k in this.savedata) {
                      // console.log(this.savedata[k].id,after[key].id);
                      if (this.savedata[k].id == after[key].id) {
                        s = s || true
                        this.savedata[k].sl = after[key].sl
                      } else {
                        s = s || false
                      }
                    }
                    if (!s) {
                      this.savedata.push(after[key])
                    }
                  }

                }
              }
            }

          } else {
            // console.log("+++++++++++++");
            // 删除掉数字，选中内容也删除
            // console.log(after[key].sl == '' || after[key].sl == undefined||after[key].sl == '0');
            if (after[key].sl == '' || after[key].sl == undefined || after[key].sl == '0') {
              // console.log(after[key].id);
              for (const ke in this.savedata) {
                if (after[key].id == this.savedata[ke].id) {
                  // console.log(ke);
                  this.savedata.splice(ke, 1)
                }
              }
              for (const ke in this.checkedCitiesdim) {
                // console.log(after[key].id , this.checkedCitiesdim[ke]);
                // console.log(after[key].id == this.checkedCitiesdim[ke]);
                if (after[key].id == this.checkedCitiesdim[ke]) {
                  // console.log(ke);
                  // console.log(']]]]]');
                  this.checkedCitiesdim.splice(ke, 1)
                }
              }
            }
          }
        }

        // console.log(this.checkedCitiesdim);
      }
    },
    checkedCities: {
      deep: true,
      handler: function (after, before) {
        // console.log("????");
        // console.log(after);
        // console.log(before);
        if (after.length < before.length) {
          // console.log(after);
          var s = JSON.parse(JSON.stringify(before));
          for (const key in s) {
            for (const ke in after) {
              if (after[ke] == s[key]) {
                s.splice(key, 1)
              }
            }
          }
          // console.log(s[0]);
          if (s.length == 1) {
            for (const key in this.savedata) {
              if (s[0] == this.savedata[key].id) {
                // console.log('[[[');
                this.savedata.splice(key, 1)
              }
            }
          }

        }
        if (after.length > before.length) {
          // console.log(after[after.length-1]);
          for (const key in this.dimoptions) {
            if (this.dimoptions[key].id == after[after.length - 1]) {
              if (this.dimoptions[key].sl != '' && this.dimoptions[key].sl != undefined && this.dimoptions[key].sl != '0') {
                // console.log(this.dimoptions[key].n);
                var s = false
                for (const ke in this.savedata) {
                  // console.log(this.savedata[ke].id ,this.dimoptions[key].id);
                  if (this.savedata[ke].id == this.dimoptions[key].id) {
                    this.savedata[ke].sl == this.dimoptions[key].sl
                    s = s || true
                  } else {
                    s = s || false
                  }
                }
                if (!s) {
                  this.savedata.push(this.dimoptions[key])
                }
              }
            }
          }
        }
      }
    },
    supp: {
      deep: true,
      handler: function (after, before) {
        // console.log(after);
        for (const key in after) {
          var reg = /^[0-9]+(\.[0-9]{0,2})?$/
          if (!reg.test(after[key].sp)) {
            this.supplies[key].sp = before[key].sp
          }
          var re = /^[0-9]*$/g
          if (!re.test(after[key].sl)) {
            this.supplies[key].sl = before[key].sl
          }

        }
      }
    },
    dimvalue: function (after, before) {
      // console.log(after);
      if (after == '') {
        this.sdadgr = false
        this.remoteMethod('')
      }
    },
    // 延迟搜索
    dimvalue: function (after, before) {
      console.log(after);
      if (this.timer) {
        clearTimeout(this.timer)
      }
      this.timer = setTimeout(() => {
        if (after == '') {
          this.sdadgr = false
          this.remoteMethod('')
        } else {
          this.remoteMethod(after)
        }
      }, 500)
    }

  }

}
</script>
<style>
    /* 靠右 */
    .sout .el-dialog {
        margin: 0px 0px 0px auto !important;
        background-color: #f9f9f9;
        height: 100%;
        position: relative;
    }

    .sout .el-dialog__footer {
        position: absolute;
        width: 100%;
        bottom: 0;
        right: 0;
        display: flex;
        justify-content: center;
    }

    .sout .el-dialog__body {
        padding: 0px 20px 30px 20px;
        overflow-y: scroll !important;
        width: calc(100% - 40px);
        height: calc(100% - 160px);
        max-height: calc(100% - 160px);
        margin: 0;
    }

    .sout .el-dialog {
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .sout {
        width: calc(100% - 40px);
        height: calc(100% - 40px);
        padding: 20px 30px;
    }

    .sout .gaib {
        width: 500px !important;
        display: flex;
        align-items: center;
    }

    .monad, .show {
        display: none;
    }

    /* 必填 */
    .sout .mandatory {
        color: #40404e;
        width: 140px;
        text-align: right;
        /* padding-top: 10px; */
        line-height: 40px;
    }

    .sout .controlling {
        width: 230px !important;
        line-height: 40px;
    }

    .sout .reqfieldsd {
        font-size: 14px;
        padding-right: 4px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* 表格内文字右对齐 */
    .sout .alignment {
        text-align: right !important;
        padding-right: 15px;
    }

    /* 表格无数据时展示 */
    .sout .tiaodd {
        position: sticky;
        left: 0;
        top: 44px;
        width: 100% !important;
        display: inline-block;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .sout .nodata {
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        padding: 0;
    }

    .sout .nodata img {
        width: 60px;
        height: 60px;
    }

    .sout .nodata .hint {
        line-height: 36px;
        font-size: 13px !important;
    }

    .sout .drag-list .nodata {
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
    }

    .sout .drag-list .nodata img {
        width: 60px;
        height: 60px;
    }

    .sout .drag-list .nodata .hint {
        font-size: 13px !important;
    }

    /* 全选字体大小 */
    .sout .zhuixiaoi .mmodity .el-checkbox__label {
        font-size: 12px;
    }

    /* 给一级分类二级分类加外边距和圆角 */
    .sout .el-radio-button {
        margin-right: 6px;
        margin-bottom: 6px;
        /* overflow: hidden; */
        /* border: 1px solid #f5f5f5; */
    }

    .sout .el-radio-button__inner {
        border-radius: 4px !important;
    }

    /* 去除瑕疵 */
    .sout .el-radio-button__orig-radio:checked + .el-radio-button__inner {
        box-shadow: none
    }

    /* 选中状态颜色背景边框 */
    .sout .el-radio-button__orig-radio:checked + .el-radio-button__inner {
        background-color: rgba(0, 0, 0, 0);
        border: 1px solid #6A9EFF !important;
        color: #6A9EFF;
    }

    .sout .sout-headline {
        font-size: 30px;
        font-weight: bold;
        color: #40404e;
    }

    .sout .sout-controller {
        height: 54px;
        background-color: #e5e5e5;
        display: flex;
        align-items: center;
    }

    .sout .sout-rkrq {
        width: 100%;
        color: #40404e;
        overflow: hidden;
        font-size: 13px;
        line-height: 14px;
    }

    .sout .sout-rkrq .rkrq {
        display: inline-flex;
        align-items: center;
        margin: 0 0 14px 0;
    }

    .sout .sout-rkrq .rkrq:nth-child(1) {
        width: 670px !important;
    }

    .sout .sout-rkrq .rkrq:nth-child(2) {
        width: 275px !important;
    }

    .sout .sout-rkrq .rkrq:nth-child(3) {
        width: 250px !important;
    }

    .sout .sout-rkrq .rkrq:nth-child(4) {
        width: 150px !important;
    }

    /* 选择近几天 */
    .sout .sout-rkrq .rkrq .danxk {
        height: 34px;
        margin-right: 10px;
        display: inline-flex;
        align-items: center;
    }

    .sout .sout-rkrq .rkrq .danxk img {
        display: inline-block;
        width: 12px;
        height: 12px;
        margin-right: 6px;
    }

    .sout .sout-rkrq .rkrq .danxk .el-radio-button {
        margin: 0px 4px;
        box-shadow: none !important;
    }

    .sout .sout-rkrq .rkrq .danxk .el-radio-button__inner {
        border-radius: 19px !important;
        border: 0px !important;
        background-color: transparent;
        color: #40404e;
        font-size: 12px;
        display: flex;
        align-items: center;
        line-height: 16px;
        padding: 5px 15px;
    }

    .sout .sout-rkrq .rkrq .danxk .el-radio-button__orig-radio:checked + .el-radio-button__inner {
        /* background-color: #2A3450 !important; */
        color: #2170ff;
    }

    .sout .ewdetai {
        color: #2170ff;
        cursor: pointer;
    }

    .sout .layouts {
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .sout .AddPrincipal {
        color: #4eadfc
    }

    .sout .compatibility {
        display: flex;
        align-items: center;
        /* margin-bottom: 10px; */

    }

    .sout .compatibils {
        margin-bottom: 10px;
    }

    .sout .required {
        width: 60px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* 取消按钮 */
    .sout .el-dialog .el-button--default {
        background-color: #ccc;
        border: 1px solid #ccc;
        color: #40404e;
    }

    .sout .Writmiddle .el-input__inner {
        text-align: right;
    }

    .sout .Writmiddle .el-input__inner::-webkit-input-placeholder {
        text-align: center;
    }

    .sout .el-dialog {
        background-color: #f9f9f9;
    }

    .sout .el-input__inner {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
        height: 30px;
        line-height: 30px;
    }

    .sout .el-dialog__title, .sout .el-dialog__headerbtn .el-dialog__close, .sout .el-form-item__label {
        color: #1a1a21;
    }

    .sout .el-input {
        width: 190px;
    }

    .sout .el-form-item {
        display: flex;
        margin: 0;
    }

    .sout .el-table th.el-table__cell.is-leaf {
        background-color: #2A2B34;
        color: #40404e;
        border-bottom: 1px solid #f5f5f5;
        border-right: 1px solid #f5f5f5;
    }

    .sout .el-checkbox__input {
        background-color: rgba(0, 0, 0, 0);
    }

    .sout .el-checkbox__input.is-disabled.is-checked .el-checkbox__inner {
        background-color: rgba(0, 0, 0, 0) !important;
    }

    .sout .el-dialog {
        width: 30vw;
    }

    .sout .has-gutter {
        border: 1px solid #f5f5f5;
    }

    .sout .el-table__body:nth-of-type(odd) {
        background-color: #1A1A20;
        color: #F0F0F0;
    }

    .sout .el-table__body:nth-of-type(even) {
        background-color: #e5e5e5;
        color: #F0F0F0;
    }

    .sout .el-table__empty-block {
        background-color: #e5e5e5 !important;
    }

    .sout .el-table__empty-text {
        color: #40404e;
    }

    .sout .el-table__body tr:hover > td {
        background-color: #3C3D46 !important;
    }

    .sout .el-table__body tr.current-row > td {
        background-color: #3C3D46 !important;
    }

    .sout .el-table__body td.el-table__cell {
        border-bottom: 1px solid #f5f5f5;
        border-right: 1px solid #f5f5f5;
    }

    /* 选中改变颜色 */
    /* .sout .el-table__body .success-row{
        background-color: #3C3D46 !important;
    } */
    .sout .el-table--border, .sout .el-table--group {
        border-top: 1px solid #f5f5f5;
        border-left: 1px solid #f5f5f5;
    }

    .sout .el-table--border::after,
    .sout .el-table--group::after,
    .sout .el-table::before {
        background-color: #f5f5f5;
    }

    .sout table thead tr th, .sout table tbody tr td {
        height: 40px;
        font-size: 14px;
    }

    .sout .el-table__body-wrapper.is-scrolling-none::-webkit-scrollbar {
        display: none !important;
    }

    .sout .el-table__body-wrapper.is-scrolling-none {
        -ms-overflow-style: none;
        overflow: -moz-scrollbars-none;
        scrollbar-width: none;
    }

    .sout .el-table__body {
        width: 100% !important;
    }

    .sout .el-table__cell.gutter {
        display: none;
    }

    .sout .el-table__header colgroup col:last-child {
        display: none;
    }

    /* 下拉框 */
    .el-select-dropdown__wrap {
        background-color: #f5f5f5;
    }

    .el-select-dropdown__empty {
        background-color: #f5f5f5;
        color: #40404e;
    }

    .el-select-dropdown__item.selected {
        background-color: #e5e5e5;
    }

    .el-select__popper.el-popper[role="tooltip"] {
        border: 1px solid #f5f5f5;
    }

    .el-select__popper.el-popper[role="tooltip"][data-popper-placement^="bottom"] .el-popper__arrow::before {
        border: 1px solid #f5f5f5;
        background-color: #f5f5f5;
    }

    .el-select-dropdown__item.hover, .el-select-dropdown__item:hover {
        background-color: #e5e5e5;
    }

    .el-select-dropdown__item.selected {
        color: #40404e;
    }

    .el-select-dropdown__item {
        color: #40404E;
    }

    .el-select-dropdown {
        border: 1px solid #f5f5f5;
    }

    .xdownbox {
        display: none;
    }

    /* 新增仓库 */
    .sout .el-tag {
        background-color: rgba(0, 0, 0, 0);
        margin-right: 10px;
        margin-bottom: 10px;
        color: #40404e;
    }

    .sout .el-tag i {
        color: #40404e;
    }

    .sout .tidsesfe {
        display: flex;
    }

    /* 多行文本输出框 */
    .sout .el-textarea__inner {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
        width: 100%;
    }

    .sout .el-input__count {
        background-color: #1A1A20;
        color: #40404e;
        right: -45px;
        height: 20px;
        bottom: 5px;
        line-height: 20px;
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* 新增物料 */
    .sout .dialogFormVisible .el-dialog {
        width: 1280px;
    }

    .sout .addmaterial {
        padding-top: 20px;
    }

    .sout .dialogFormVisible .rkrq {
        width: 1240px;
        height: 54px;
        background-color: #e5e5e5;
        display: flex;
        align-items: center;
    }

    .sout .dialogFormVisible .zhuixiaoi {
        width: 1240px;
    }

    .sout .dialogFormVisible .limiting {
        max-height: 320px !important;
        overflow-y: scroll;
    }

    .sout .dialogFormVisible .zhuixiaoi .el-checkbox-group {
        height: 40px;
        line-height: 36px !important;
    }

    .sout .dialogFormVisible .drag-list td:nth-of-type(2), .sout .dialogFormVisible .mmodity th:nth-of-type(2) {
        width: 180px;
    }

    .sout .dialogFormVisible .drag-list td:nth-of-type(3), .sout .dialogFormVisible .mmodity th:nth-of-type(3) {
        width: 140px;
    }

    .sout .dialogFormVisible .drag-list td:nth-of-type(4), .sout .dialogFormVisible .mmodity th:nth-of-type(4) {
        width: 140px;
    }

    .sout .dialogFormVisible .drag-list td:nth-of-type(5), .sout .dialogFormVisible .mmodity th:nth-of-type(5) {
        width: 110px;
    }

    .sout .dialogFormVisible .drag-list td:nth-of-type(6), .sout .dialogFormVisible .mmodity th:nth-of-type(6) {
        width: 100px;
    }

    .sout .dialogFormVisible .drag-list td:nth-of-type(7), .sout .dialogFormVisible .mmodity th:nth-of-type(7) {
        width: 100px;
    }

    .sout .dialogFormVisible .el-input-number {
        width: 100%;
    }

    /* 查看详情 */
    .sout .viewdetailscls .el-dialog {
        width: 1280px;
        /* width: 80vw !important; */
        /* min-width: 520px !important;
        max-width:540px !important; */
    }

    /* 必填 */
    .sout .viewdetailscls .mandatory {
        color: #40404e;
    }

    /* .sout .viewdetailscls .el-form{
        padding-top: 20px;
    } */
    .sout .viewdetailscls .addmaterial {
        /* display: flex;
        justify-content: center; */
        margin-left: 20px;
        width: 1190px;
    }

    .sout .viewdetailscls .addmaterial .zhuixiaoi {
        width: 100%;
    }

    .sout .viewdetailscls .materialnr {
        width: 200px;
    }

    .sout .viewdetailscls .materialnrs {
        width: 600px;
    }

    .sout .viewdetailscls .mldw {
        font-size: 18px;
        color: #40404e;
        margin-left: 20px;
    }

    .sout .viewdetailscls .el-form {
        padding: 0px;
        margin: 20px;
        background-color: #eee;
        border-radius: 8px
    }
    
    .sout .el-textarea__inner{
      border-color: rgb(217, 217, 217);
    }

    /* 明细单列表 */
    .sout .viewdetailscls .materialnr, .sout .viewdetailscls label, .sout .viewdetailscls .materialnrs {
        color: #40404e;
        font-size: 14px;
    }

    .sout .viewdetailscls .drag-list td:nth-of-type(1), .sout .viewdetailscls .mmodity th:nth-of-type(1) {
        width: 50px;
    }

    .sout .viewdetailscls .drag-list td:nth-of-type(2), .sout .viewdetailscls .mmodity th:nth-of-type(2) {
        width: 150px;
    }

    .sout .viewdetailscls .drag-list td:nth-of-type(3), .sout .viewdetailscls .mmodity th:nth-of-type(3) {
        width: 130px;
    }

    .sout .viewdetailscls .drag-list td:nth-of-type(4), .sout .viewdetailscls .mmodity th:nth-of-type(4) {
        width: 130px;
    }

    .sout .viewdetailscls .drag-list td:nth-of-type(5), .sout .viewdetailscls .mmodity th:nth-of-type(5) {
        width: 90px;
    }

    .sout .viewdetailscls .drag-list td:nth-of-type(6), .sout .viewdetailscls .mmodity th:nth-of-type(6) {
        width: 100px;
    }

    .sout .viewdetailscls .drag-list td:nth-of-type(7), .sout .viewdetailscls .mmodity th:nth-of-type(7) {
        width: 100px;
    }

    .sout .viewdetailscls .drag-list td:nth-of-type(8), .sout .viewdetailscls .mmodity th:nth-of-type(8) {
        width: 110px;
    }

    .sout .viewdetailscls .drag-list td:nth-of-type(9), .sout .viewdetailscls .mmodity th:nth-of-type(9) {
        width: 100px;
    }

    /* 红冲操作单列表 */
    .sout .viewdetailscls .addmassrial {
        margin-left: 20px;
        max-width: 1190px;
        overflow-x: scroll;
    }

    .sout .viewdetailscls .addmassrial .zhuixiaoi {
        width: auto;
    }

    .sout .viewdetailscls .addmassrial .drag-list td:nth-of-type(1), .sout .viewdetailscls .addmassrial .mmodity th:nth-of-type(1) {
        width: 50px;
    }

    .sout .viewdetailscls .addmassrial .drag-list td:nth-of-type(2), .sout .viewdetailscls .addmassrial .mmodity th:nth-of-type(2) {
        width: 150px;
    }

    .sout .viewdetailscls .addmassrial .drag-list td:nth-of-type(3), .sout .viewdetailscls .addmassrial .mmodity th:nth-of-type(3) {
        width: 120px;
    }

    .sout .viewdetailscls .addmassrial .drag-list td:nth-of-type(4), .sout .viewdetailscls .addmassrial .mmodity th:nth-of-type(4) {
        width: 90px;
    }

    .sout .viewdetailscls .addmassrial .drag-list td:nth-of-type(5), .sout .viewdetailscls .addmassrial .mmodity th:nth-of-type(5) {
        width: 100px;
    }

    .sout .viewdetailscls .addmassrial .drag-list td:nth-of-type(6), .sout .viewdetailscls .addmassrial .mmodity th:nth-of-type(6) {
        width: 100px;
    }

    .sout .viewdetailscls .addmassrial .drag-list td:nth-of-type(7), .sout .viewdetailscls .addmassrial .mmodity th:nth-of-type(7) {
        width: 100px;
    }

    .sout .viewdetailscls .addmassrial .drag-list td:nth-of-type(8), .sout .viewdetailscls .addmassrial .mmodity th:nth-of-type(8) {
        width: 90px;
    }

    .sout .viewdetailscls .addmassrial .drag-list td:nth-of-type(9), .sout .viewdetailscls .addmassrial .mmodity th:nth-of-type(9) {
        width: 120px;
    }

    .sout .viewdetailscls .addmassrial .drag-list td:nth-of-type(10), .sout .viewdetailscls .addmassrial .mmodity th:nth-of-type(10) {
        width: 110px;
    }

    /* 红冲 */
    .sout .hcwdetailscls .el-dialog {
        width: 1280px;
    }

    .sout .hcwdetailscls .el-form {
        padding-top: 20px;
        padding: 0px;
        margin: 20px;
        background-color: #eee;
        border: 1px solid #f5f5f5;
        border-radius: 8px
    }

    /* 必填 */
    .sout .hcwdetailscls .mandatory {
        color: #40404e;
    }

    .sout .hcwdetailscls .addmaterial {
        /* display: flex;
        justify-content: center; */
        margin-left: 20px;
        max-width: 1190px;
        overflow-x: scroll;
    }

    .sout .hcwdetailscls .addmaterial .zhuixiaoi {
        width: auto;
    }

    .sout .hcwdetailscls .materialnr {
        width: 200px;
    }

    .sout .hcwdetailscls .materialnrs {
        width: 600px;
    }

    .sout .hcwdetailscls .el-input-number {
        width: 100%;
    }

    .sout .hcwdetailscls .materialnr, .sout .hcwdetailscls label, .sout .hcwdetailscls .materialnrs {
        color: #40404e;
        font-size: 14px;
    }

    .sout .hcwdetailscls .drag-list td:nth-of-type(2), .sout .hcwdetailscls .mmodity th:nth-of-type(2) {
        width: 150px;
    }

    .sout .hcwdetailscls .drag-list td:nth-of-type(3), .sout .hcwdetailscls .mmodity th:nth-of-type(3) {
        width: 140px;
    }

    .sout .hcwdetailscls .drag-list td:nth-of-type(4), .sout .hcwdetailscls .mmodity th:nth-of-type(4) {
        width: 140px;
    }

    .sout .hcwdetailscls .drag-list td:nth-of-type(5), .sout .hcwdetailscls .mmodity th:nth-of-type(5) {
        width: 100px;
    }

    .sout .hcwdetailscls .drag-list td:nth-of-type(6), .sout .hcwdetailscls .mmodity th:nth-of-type(6) {
        width: 100px;
    }

    .sout .hcwdetailscls .drag-list td:nth-of-type(7), .sout .hcwdetailscls .mmodity th:nth-of-type(7) {
        width: 100px;
    }

    .sout .hcwdetailscls .drag-list td:nth-of-type(8), .sout .hcwdetailscls .mmodity th:nth-of-type(8) {
        width: 110px;
    }

    .sout .hcwdetailscls .drag-list td:nth-of-type(9), .sout .hcwdetailscls .mmodity th:nth-of-type(9) {
        width: 100px;
    }

    .sout .hcwdetailscls .drag-list td:nth-of-type(10), .sout .hcwdetailscls .mmodity th:nth-of-type(10) {
        width: 100px;
    }

    .sout .hcwdetailscls .drag-list td:nth-of-type(11), .sout .hcwdetailscls .mmodity th:nth-of-type(11) {
        width: 100px;
    }

    .sout .hcwdetailscls .drag-list td:nth-of-type(12), .sout .hcwdetailscls .mmodity th:nth-of-type(12) {
        width: 100px;
    }

    /* 添加物料 */
    /* 模糊查询 */
    .sout .search .el-dialog {
        width: 1280px;
        /* width: 50vw !important;
        min-width: 550px !important;
        max-width:560px !important; */
    }

    .sout .search .topwidth {
        width: 300px;
        margin-top: 30px;
    }

    /* 物料信息 */
    .sout .search .materialsoutformation {
        margin-top: 5px;
        padding-top: 10px;
        /* border-top:2px solid rgb(88, 88, 88) ; */
    }

    .sout .search .materialsoutformation .information {
        color: #40404e;
        font-size: 14px;
        margin-bottom: 12px;
    }

    .sout .search .materialsoutformation .materialnr {
        color: #40404e;
    }

    .sout .search .materialsoutformation .protyfsfg {
        margin: 0 0 10px;
        color: #40404e;
        width: 360px;
        display: flex;
        justify-content: space-between;
    }

    .sout .search .materialsoutformation .protyfsfg input {
        width: 230px;
    }

    .sout .search .materialsoutformation .xzrr {
        margin-left: 30px;
    }

    .sout .search .el-input-number {
        width: 100%;
    }

    .sout .search .zhuixiaoi {
        width: 1240px;
    }

    .sout .search .limiting {
        max-height: 320px !important;
        overflow-y: scroll;
    }

    .sout .search .zhuixiaoi .el-checkbox-group {
        height: 40px;
        line-height: 36px !important;
    }

    /* .sout .search .drag-list td:nth-of-type(1),.sout .search .mmodity th:nth-of-type(1){
        width: 180px;
    } */
    .sout .search .drag-list td:nth-of-type(2), .sout .search .mmodity th:nth-of-type(2) {
        width: 200px;
    }

    .sout .search .drag-list td:nth-of-type(3), .sout .search .mmodity th:nth-of-type(3) {
        width: 120px;
    }

    .sout .search .drag-list td:nth-of-type(4), .sout .search .mmodity th:nth-of-type(4) {
        width: 100px;
    }

    .sout .search .drag-list td:nth-of-type(5), .sout .search .mmodity th:nth-of-type(5) {
        width: 110px;
    }

    .sout .search .drag-list td:nth-of-type(6), .sout .search .mmodity th:nth-of-type(6) {
        width: 110px;
    }

    .sout .search .drag-list td:nth-of-type(7), .sout .search .mmodity th:nth-of-type(7) {
        width: 120px;
    }

    /* 仓库列表 */
    .zsykd {
        width: 100%;
        overflow-x: scroll !important;
    }

    .sout .zhuixiaoi {
        width: 1600px;
        /* overflow: hidden; */
        border-collapse: collapse;
        color: #40404e;
    }

    .sout .zhuixiaoi .mmodity tr th {
        height: 36px;
        line-height: 36px;
        text-align: left;
        font-size: 14px;
        font-weight: 600;
        color: #40404e;
        padding-left: 20px;
    }
    .sout .zhuixiaoi .mmodity tr th .el-checkbox__label {
        font-size: 14px;
        font-weight: 600;
        color: #40404e;
    }

    .sout .zhuixiaoi .limiting .drag-list td {
        height: 36px;
        line-height: 36px;
        text-align: left;
        white-space: normal;
        word-break: break-all;
        font-size: 14px;
        font-weight: 400;
        padding-left: 20px;
    }

    .sout .zhuixiaoi .limiting .drag-list {
        border-top: solid 1px #f5f5f5;
        display: block;
        /* width: calc(100% - 17px); */
        display: flex;
    }

    .sout .zhuixiaoi .mmodity {
        width: 100%;
        display: block;
    }

    .sout .zhuixiaoi .mmodity tr {
        background-color: #f5f5f5;
        display: flex;
    }

    .sout .zhuixiaoi .limiting {
        border-bottom: solid 1px #f5f5f5;
        overflow-y: auto !important;
        max-height: 540px;
        display: block;
    }

    .sout .drag-list td:nth-of-type(1), .sout .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .sout .mmodity th:nth-of-type(2), .sout .drag-list td:nth-of-type(2) {
        width: 110px;
    }

    .sout .drag-list td:nth-of-type(3), .sout .mmodity th:nth-of-type(3) {
        width: 130px;
    }

    .sout .drag-list td:nth-of-type(4), .sout .mmodity th:nth-of-type(4) {
        width: 140px;
    }

    .sout .drag-list td:nth-of-type(5), .sout .mmodity th:nth-of-type(5) {
        width: 140px;
    }

    .sout .drag-list td:nth-of-type(6), .sout .mmodity th:nth-of-type(6) {
        width: 140px;
    }

    .sout .drag-list td:nth-of-type(7), .sout .mmodity th:nth-of-type(7) {
        width: 200px;
    }

    .sout .drag-list td:nth-of-type(8), .sout .mmodity th:nth-of-type(8) {
        width: 140px;
    }

    .sout .drag-list td:nth-of-type(8), .sout .mmodity th:nth-of-type(8) {
        width: 140px;
    }

    .sout .drag-list:nth-of-type(odd) {
        background-color: #f9f9f9;
        color: #40404e;
    }

    .sout .drag-list:nth-of-type(even) {
        background-color: #f5f5f5;
        color: #40404e;
    }

    .sout .zhuixiaoi .el-checkbox__label {
        color: #40404e;
    }

    /*  */
    .sout .zhuixiaoi .chaoguogai {
        height: 20px;
        /* text-align: center; */
        line-height: 20px;
        width: 136px;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }

    /* 日期选择器 */
    .sout .sout-rkrq .rkrq .el-range-editor .el-range-input {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
    }

    .sout .sout-rkrq .rkrq .el-date-editor .el-range-separator, .sout .sout-rkrq .rkrq .el-date-editor .el-range__icon {
        color: #40404e;
        line-height: 22px;
    }

    .el-picker-panel {
        background-color: #1A1A20;
    }

    /* 年月日 */
    .el-date-range-picker__header {
        color: #40404e;
    }

    /* 加减年月  */
    .el-icon-d-arrow-left, .el-icon-arrow-left, .el-icon-d-arrow-right, .el-icon-arrow-right {
        color: #40404e;
    }

    .el-date-table tbody tr th {
        color: #40404e;
    }

    .el-date-table td.next-month, .el-date-table td.prev-month {
        color: #77797c;
    }

    .el-picker-panel {
        color: #40404e;
    }

    .in-range {
        color: #000;
    }

    .el-date-table td.in-range div {
        background-color: #F2F6FC;
    }

    /* 分页 */
    .sout .Pagination {
        /* width: 1093px; */
        text-align: right;
        margin-top: 20px;
    }

    .sout .Pagination .el-pagination.is-background .btn-next, .sout .Pagination .el-pagination.is-background .btn-prev, .sout .Pagination .el-pagination.is-background .el-pager li {
        background-color: rgba(0, 0, 0, 0);
        border: 1px solid #606266;
        color: #40404e;
    }

    .sout .Pagination .btn-prev {
        background-color: rgba(0, 0, 0, 0);
        border: 1px solid #606266;
    }

    .sout .Pagination .el-pagination {
        padding: 0;
    }

    .sout .Pagination .el-pagination .btn-next .el-icon, .sout .Pagination .el-pagination .btn-prev .el-icon {
        color: #40404e;
    }

    .sout .Pagination .el-pagination.is-background .el-pager li:not(.disabled).active {
        color: #409EFF;
        background-color: rgba(0, 0, 0, 0);
        border: 1px solid #409EFF;
    }
</style>

<style media="print">
    @page {
        size: auto A4 landscape;
        margin: 5mm;
    }

    @media print {
        html {
            /* margin-left: 30px; */
        }

        .printsout .conceal {
            display: none;
        }

        .printsout .show {
            display: block;
        }

        .printsout .monad {
            font-weight: bold;
            display: block;
            font-size: 30px;
            margin-top: 50px;
            color: #000;
            text-align: center;
        }

        .printsout .tidsesfe {
            display: flex;
        }

        .printsout .compatibility {
            display: flex;
            align-items: center;
        }

        .printsout .mandatory {
            color: #000;
            width: 140px;
            text-align: right;
            /* padding-top: 10px; */
        }

        .printsout .controlling {
            width: 370px !important;
            line-height: 40px;
        }

        .printsout .reqfieldsd {
            font-size: 14px;
            padding-right: 4px;
            color: #ce4153;
            /* 文字不可选中 */
            -webkit-user-select: none;
            -moz-user-select: none;
            -ms-user-select: none;
            user-select: none;
        }

        .printsout .zhuixiaoi {
            overflow: hidden;
            border-collapse: collapse;
            color: #000;
        }

        .printsout .zhuixiaoi .mmodity tr th {
            height: 40px;
            line-height: 40px;
            text-align: center;
            /* border: solid 1px #f5f5f5; */
            border-top: solid 1px #f5f5f5;
            border-right: solid 1px #f5f5f5;
            border-bottom: solid 1px #f5f5f5;
            background-color: #2d2e38;
            font-weight: 400;
        }

        .printsout .zhuixiaoi .mmodity th:nth-of-type(1) {
            border-left: solid 1px #f5f5f5;
        }

        .printsout .zhuixiaoi .limiting .drag-list td {
            height: 40px;
            line-height: 40px;
            text-align: center;
            white-space: normal;
            word-break: break-all;
            /* border: solid 1px #f5f5f5; */
            border-bottom: solid 1px #f5f5f5;
            border-right: solid 1px #f5f5f5;
        }

        .printsout .zhuixiaoi .limiting .drag-list td:nth-of-type(1) {
            border-left: solid 1px #f5f5f5;
        }

        .printsout .zhuixiaoi .limiting .drag-list {
            display: block;
            display: flex;

        }

        .printsout .zhuixiaoi .mmodity {
            width: 100%;
            display: block;
        }

        .printsout .zhuixiaoi .mmodity tr {
            display: flex;
        }

        .printsout .el-form-item {
            display: flex;
            margin: 0;
        }

        .printsout .drag-list td, .printsout .mmodity th {
            font-size: 13px;
        }

        .printsout .el-dialog {
            width: 1100px;
        }

        .printsout .el-form {
            padding-top: 10px;
        }

        .printsout .addmaterial {
            display: flex;
            /* justify-content: center; */
            margin-left: 30px;
        }

        .printsout .materialnr {
            width: 200px;
        }

        .printsout .materialnrs {
            width: 600px;
        }

        .printsout .materialnr, .printsout label, .printsout .materialnrs {
            color: #000;
        }

        .printsout .drag-list td:nth-of-type(1), .printsout .mmodity th:nth-of-type(1) {
            width: 60px;
        }

        .printsout .drag-list td:nth-of-type(2), .printsout .mmodity th:nth-of-type(2) {
            width: 200px;
        }

        .printsout .drag-list td:nth-of-type(3), .printsout .mmodity th:nth-of-type(3) {
            width: 160px;
        }

        .printsout .drag-list td:nth-of-type(4), .printsout .mmodity th:nth-of-type(4) {
            width: 50px;
        }

        .printsout .drag-list td:nth-of-type(5), .printsout .mmodity th:nth-of-type(5) {
            width: 80px;
        }

        .printsout .drag-list td:nth-of-type(6), .printsout .mmodity th:nth-of-type(6) {
            width: 80px;
        }

        .printsout .drag-list td:nth-of-type(7), .printsout .mmodity th:nth-of-type(7) {
            width: 90px;
        }

        .printsout .drag-list td:nth-of-type(8), .printsout .mmodity th:nth-of-type(8) {
            width: 90px;
        }

        .printsout .drag-list td:nth-of-type(9), .printsout .mmodity th:nth-of-type(9) {
            width: 110px;
        }

        .printsout .drag-list td:nth-of-type(10), .printsout .mmodity th:nth-of-type(10) {
            width: 100px;
        }

        .printsout .signature {
            display: flex;
            margin-top: 30px;
        }

        .printsout .signature > div {
            margin-left: 30px;
            display: flex;
        }

        .printsout .signature span {
            font-size: 20px;
        }

        .printsout .signature .xian {
            width: 180px;
            height: 30px;
            border-bottom: 1px solid #000;
        }
    }

    .el-input__icon {
        line-height: 30px;
    }

    .out_sum .el-input {
        opacity: 1;
        width: 190px;
    }

    .el-button {
        font-size: 13px;
        line-height: 14px;
        padding: 8px 20px;
        height: 30px;
    }

    .el-range-editor.el-input__inner {
        width: 287px;
        height: 30px;
        line-height: 30px;
    }

    .el-date-editor .el-range__close-icon {
        line-height: 22px;
    }

    .dialogFormVisible .el-input, .addprincipal .el-input, .hcwdetailscls .el-input, .search .el-input {
        width: 100%;
    }

    .drag-list-check {
        /* background: rgba(39, 52, 82, .5) !important; */
    }


</style>
