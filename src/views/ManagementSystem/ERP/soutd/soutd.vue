<template>
    <div class="soutd">
        <div class="stairfl">
            <div>状&emsp;&emsp;态：</div>
            <div class="stairastrict">
                <el-radio-group v-model="Inbound.state" class="container">
                    <el-radio-button label="0">全部</el-radio-button>
                    <el-radio-button label="2">整单红冲</el-radio-button>
                    <el-radio-button label="6">待收货</el-radio-button>
                    <el-radio-button label="7">异议中</el-radio-button>
                    <el-radio-button label="9">异议已处理</el-radio-button>
                    <el-radio-button label="5">已完成</el-radio-button>
                </el-radio-group>
            </div>
        </div>
        <div class="soutd-rkrq">
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
                <span>出库仓库：</span>
                <el-select v-model="Inbound.cklx" placeholder="全部" clearable @change="demand">
                    <el-option label="全部" value="0"></el-option>
                    <el-option v-for="(item,i) in cklxnr" :key="i" :label="item.n" :value="item.id"></el-option>
                </el-select>
            </div>
            <div class="rkrq">
                <span>备注：</span>
                <el-input v-model="Inbound.remark" @input="demand" placeholder="请输入备注模糊搜索"></el-input>
            </div>
            <div class="rkrq">
                <!-- <el-button type="primary" @click="demand">查询</el-button> -->
                <el-button type="primary" @click="resetstorage">重置</el-button>
            </div>
        </div>

        <div class="soutd-controller">
            <icon-button @click.native="xingh" text="新增" img="btn_add.png" colors="#f5f5f5"></icon-button>
            <characters-button @click.native="compileprinter" colors="#f5f5f5" wz='红冲'></characters-button>
            <characters-button @click.native="noneffective" colors="#f5f5f5" wz='整单红冲'></characters-button>
            <characters-button @click.native="effective" colors="#f5f5f5" wz='类似创建'></characters-button>
        </div>
        <div style="position: relative">
            <div style="display: inline-block;" class="zsykd">
                <table class="zhuixiaoi">
                    <thead class="mmodity">
                    <tr>
                        <th>
                            <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll" @change="handleCheckAllChange">
                                全选
                            </el-checkbox>
                        </th>
                        <th>单号</th>
                        <th>出库仓库</th>
                        <th>入库仓库</th>
                        <th>
                            <div class="alignment">出库成本</div>
                        </th>
                        <th>状态</th>
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
                            <ellipsis-tooltip :text="item.osn || '-----'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.isn || '-----'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <div class="alignment">{{item.ta}}</div>
                        </td>
                        <td>{{item.s}}</td>
                        <td>
                            <ellipsis-tooltip :text="item.r || '-----'"></ellipsis-tooltip>
                        </td>
                        <td>{{item.ost}}</td>
                        <td>{{item.oen}}</td>
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
            <div style="display: inline-block;position: absolute;top: 0;left: 0;z-index: 100;background-color: #f9f9f9;" >
                <table class="zhuixiaoi zhuixiaoi_l" style="width: auto;">
                    <thead class="mmodity">
                    <tr>
                        <th>
                            <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll" @change="handleCheckAllChange">
                                全选
                            </el-checkbox>
                        </th>
                        <th>单号</th>
                        <th>出库仓库</th>
                        <th>入库仓库</th>
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
                            <ellipsis-tooltip :text="item.osn || '-----'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.isn || '-----'"></ellipsis-tooltip>
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


        <!-- 调拨出库 -->
        <div v-show="dialogFormVisible" class="dialogFormVisible">
            <el-dialog title="调拨出库" :visible.sync="dialogFormVisible" @close="dialogFormVisible = false"
                       :close-on-click-modal="false">
                <el-form label-position="left">
                    <div class="tidsesfe">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd">*</span>出库仓库：
                            </div>
                            <el-select v-model="ProductLibrary.warehouse" class="controlling" placeholder="请选择出库仓库"
                                       clearable>
                                <el-option v-for="(each,i) in ProductLibrary.warehousess" :key="i" :label="each.n"
                                           :value="each.id"></el-option>
                            </el-select>
                        </div>
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd">*</span>入库仓库：
                            </div>
                            <el-select v-model="ProductLibrary.pustorage" class="controlling" placeholder="请选择入库仓库"
                                       clearable>
                                <el-option v-for="(each,i) in ProductLibrary.pustorageses" :key="i" :label="each.n"
                                           :value="each.id"></el-option>
                            </el-select>
                        </div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>备注：
                        </div>
                        <el-input type="textarea" class="controlling" v-model="ProductLibrary.remark" :rows="3"
                                  placeholder="请输入备注" show-word-limit
                                  :class="form_rule_msg_remark?'error':''" @blur="validator('remark')"/>
                        <div class="cwts">{{form_rule_msg_remark}}</div>
                    </div>
                </el-form>
                <div class="addmaterial">
                    <div class="rkrq">
                        <icon-button @click.native="appendmaterial" text="添加物料" img="btn_add.png"
                                     colors="#f5f5f5"></icon-button>
                        <icon-button @click.native="batchDeleteSupplies" text="批量删除" img="btn_delete.png" colors="#6B2830"
                                     bjcolors="#491E24"></icon-button>
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
                            <th>一级单位</th>
                            <th>二级单位</th>
                            <th>单位</th>
                            <th>出库数量</th>
                            <th v-if="paramsPrdList && isFirst">当前可用数量</th>
                            <th>出库成本小计</th>
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
                            </td>
                            <td v-if="paramsPrdList && isFirst">
                                <ellipsis-tooltip :text="item.c || '-----'"></ellipsis-tooltip>
                            </td>
                            <td>
                                <div class="alignment">{{isNaN(((item.a/item.c)*item.sl).toFixed(2)) ? '0.00' : ((item.a/item.c)*item.sl).toFixed(2)}}</div>
                            </td>

                        </tr>
                        </tbody>
                    </table>
                    <div class="tiaodd" v-if="supplies.length<1">
                        <td class="nodata">
                            <img src="../../../../assets/img/wu.png" alt="">
                            <div class="hint">暂无数据</div>
                        </td>
                    </div>
                </div>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="dialogFormVisible = false;isFirst=false">取消</el-button>
                    <el-button type="primary" @click="construction">确认</el-button>
                </span>
            </el-dialog>
        </div>
        <!-- 添加物料 -->
        <div class="search" v-show="addprincipal">
            <el-dialog title="添加物料" :visible.sync="addprincipal" @close="addprinddawcipal"
                       :close-on-click-modal="false">
                <el-input v-model="dimvalue" placeholder="请输入物料拼音首字母或名称的关键词" clearable ref="selectsse"
                          class="topwidth"></el-input>
                <div class="materialsoutformation">
                    <div class="information">出库：（勾选出库物料）</div>
                    <table class="zhuixiaoi">
                        <thead class="mmodity">
                        <tr>
                            <th>序号</th>
                            <th>物料名称</th>
                            <th>基本单位</th>
                            <th>
                                <div class="alignment">当前库存</div>
                            </th>
                            <th>出库数量</th>
                        </tr>
                        </thead>
                        <tbody class="limiting" :style="{'border-bottom':dimoptions.length<1?'0px':''}">
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
                                <el-input v-model="item.sl" placeholder="请输入数量" class="Writmiddle"/>
                            </td>
                        </tr>
                        </tbody>
                    </table>
                    <div class="tiaodd" v-if="dimoptions.length<1">
                        <td class="nodata">
                            <img src="../../../../assets/img/wu.png" alt="">
                            <div class="hint">暂无数据</div>
                        </td>
                    </div>
                </div>
                <div class="materialsoutformation">
                    <div class="information">已选待调拨物料：</div>
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
                <div id="print">
                    <div class="printsoutd">
                        <div class="monad">调拨出库单</div>
                        <div class="form m-t-6" style="background: #eee;border-radius:10px">
                          <div class="row" layout="row" layout-align="start center">
                            <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                              <div class="label" style="width:150px;text-align:right">单号：</div>
                              <div class="value" style="width:150px">{{viewdetails.code}}</div>
                            </div>
                            <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                              <div class="label" style="width:150px;text-align:right">出库操作员名称：</div>
                              <div class="value" style="width:150px">{{viewdetails.out_emp_name}}</div>
                            </div>
                            <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                              <div class="label" style="width:150px;text-align:right">出库仓库名：</div>
                              <div class="value" style="width:150px">{{viewdetails.out_store_name}}</div>
                            </div>
                          </div>
                          <div class="row" layout="row" layout-align="start center">
                            <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                              <div class="label" style="width:150px;text-align:right">入库仓库名：</div>
                              <div class="value" style="width:150px">{{viewdetails.in_store_name}}</div>
                            </div>
                            <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                              <div class="label" style="width:150px;text-align:right">出库时间：</div>
                              <div class="value" style="width:150px">{{viewdetails.out_store_time}}</div>
                            </div>
                            <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                              <div class="label" style="width:150px;text-align:right">入库时间：</div>
                              <div class="value" style="width:150px">{{viewdetails.in_store_time}}</div>
                            </div>
                          </div>
                          <div class="row" layout="row" layout-align="start center">
                            <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                              <div class="label" style="width:150px;text-align:right">出库总成本：</div>
                              <div class="value" style="width:150px">{{viewdetails.in_store_name}}</div>
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
                                        <span class="reqfieldsd"></span>出库操作员名称：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.out_emp_name }}</div>
                                </div>
                                <div class="compatibility">
                                    <div class="mandatory" style="">
                                        <span class="reqfieldsd"></span>出库仓库名：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.out_store_name }}</div>
                                </div>
                            </div>
                            <div class="tidsesfe">
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>入库仓库名：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.in_store_name }}</div>
                                </div>
                                <div class="compatibility">
                                    <div class="mandatory" style="">
                                        <span class="reqfieldsd"></span>出库时间：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.out_store_time }}</div>
                                </div>
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>入库时间：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.in_store_time }}</div>
                                </div>
                            </div>
                            <div class="tidsesfe">
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>出库总成本：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.total_amt }}</div>
                                </div>
                            </div>
                            <div class="tidsesfe">
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>备注：
                                    </div>
                                    <div class="materialnr gaib">{{viewdetails.remark || '---'}}</div>
                                </div>
                            </div>

                        </el-form> -->
                        <div class="dindan" style="line-height: 50px" v-show="viewdetails.dtls">已完成项</div>
                        <div class="addmaterial" v-show="viewdetails.dtls">
                            <div>
                                <table border style="border-collapse:collapse">
                                    <thead>
                                      <tr layout="row" layout-align="start center">
                                        <th style="padding-left:4px;width:60px;text-align:left;line-height:40px">序号</th>
                                        <th style="padding-left:4px;width:100px;text-align:left;line-height:40px">物料名称</th>
                                        <th style="padding-left:4px;width:100px;text-align:left;line-height:40px">一级分类</th>
                                        <th style="padding-left:4px;width:100px;text-align:left;line-height:40px">二级分类</th>
                                        <th style="padding-left:4px;width:100px;text-align:left;line-height:40px">单位</th>
                                        <th style="padding-left:4px;width:100px;text-align:left;line-height:40px">成本单价</th>
                                        <th style="padding-left:4px;width:100px;text-align:left;line-height:40px">数量</th>
                                        <th style="padding-left:4px;width:100px;text-align:left;line-height:40px">成本小计</th>
                                        <th style="padding-left:4px;width:100px;text-align:left;line-height:40px">状态</th>
                                      </tr>
                                    </thead>
                                    <tbody>
                                      <tr v-for="(item,i) in viewdetails.dtls" :key="i" layout="row" layout-align="start center">
                                        <td style="padding-left:4px;width:60px;text-align:left;line-height:40px">{{i+1}}</td>
                                        <td style="padding-left:4px;width:100px;text-align:left;line-height:40px">{{item.n || '---'}}</td>
                                        <td style="padding-left:4px;width:100px;text-align:left;line-height:40px">{{item.moc || '---'}}</td>
                                        <td style="padding-left:4px;width:100px;text-align:left;line-height:40px">{{item.mtc || '---'}}</td>
                                        <td style="padding-left:4px;width:100px;text-align:left;line-height:40px">{{item.un || '---'}}</td>
                                        <td style="padding-left:4px;width:100px;text-align:left;line-height:40px">{{(item.a/item.c).toFixed(2)}}</td>
                                        <td style="padding-left:4px;width:100px;text-align:left;line-height:40px">{{item.c}}</td>
                                        <td style="padding-left:4px;width:100px;text-align:left;line-height:40px">{{item.a}}</td>
                                        <td style="padding-left:4px;width:100px;text-align:left;line-height:40px">{{item.s || '---'}}</td>
                                      </tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                        <div class="dindan" v-show="viewdetails.hc_dtls">红冲记录</div>
                        <div class="addmaterial " v-show="viewdetails.hc_dtls">
                            <div>
                                <table border style="border-collapse:collapse">
                                    <thead>
                                      <tr layout="row" layout-align="start center">
                                        <th style="padding-left:4px;width:40px;text-align:left;line-height:40px">序号</th>
                                        <th class="one-txt-cut" style="padding-left:4px;width:100px;text-align:left;line-height:40px">物料名称</th>
                                        <th style="padding-left:4px;width:60px;text-align:left;line-height:40px">一级分类</th>
                                        <th style="padding-left:4px;width:60px;text-align:left;line-height:40px">二级分类</th>
                                        <th style="padding-left:4px;width:60px;text-align:left;line-height:40px">单位</th>
                                        <th style="padding-left:4px;width:80px;text-align:left;line-height:40px">红冲前数量</th>
                                        <th style="padding-left:4px;width:70px;text-align:left;line-height:40px">红冲数量</th>
                                        <th style="padding-left:4px;width:80px;text-align:left;line-height:40px">红冲后数量</th>
                                        <th style="padding-left:4px;width:100px;text-align:left;line-height:40px">红冲成本小计</th>
                                        <th style="padding-left:4px;width:80px;text-align:left;line-height:40px">红冲操作人</th>
                                        <th style="padding-left:4px;width:120px;text-align:left;line-height:40px">日期</th>
                                      </tr>
                                    </thead>
                                    <tbody>
                                      <tr layout="row" layout-align="start center" v-for="(item,i) in viewdetails.hc_dtls" :key="i">
                                        <td style="padding-left:4px;width:40px;text-align:left;line-height:40px">{{i+1}}</td>
                                        <td class="one-txt-cut" style="padding-left:4px;width:100px;text-align:left;line-height:40px">{{item.n || '---'}}</td>
                                        <td style="padding-left:4px;width:60px;text-align:left;line-height:40px">{{item.moc || '---'}}</td>
                                        <td style="padding-left:4px;width:60px;text-align:left;line-height:40px">{{item.mtc || '---'}}</td>
                                        <td style="padding-left:4px;width:60px;text-align:left;line-height:40px">{{item.mun || '---'}}</td>
                                        <td style="padding-left:4px;width:80px;text-align:left;line-height:40px">{{item.bc}}</td>
                                        <td style="padding-left:4px;width:70px;text-align:left;line-height:40px">{{item.cnt}}</td>
                                        <td style="padding-left:4px;width:80px;text-align:left;line-height:40px">{{item.ac}}</td>
                                        <td style="padding-left:4px;width:100px;text-align:left;line-height:40px">{{item.amt}}</td>
                                        <td style="padding-left:4px;width:80px;text-align:left;line-height:40px">{{item.oen || '---'}}</td>
                                        <td style="padding-left:4px;width:120px;text-align:left;line-height:40px">{{item.ot || '---'}}</td>
                                      </tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                        <div class="dindan" v-show="viewdetails.yy_dtls">异议项</div>
                        <div class="addmaterial" v-show="viewdetails.yy_dtls">
                            <div class="juz">
                                <table class="zhuixiaoi">
                                    <thead class="mmodity">
                                      <tr layout="row" layout-align="start center">
                                        <th style="padding-left:4px;width:60px;text-align:left;line-height:40px">序号</th>
                                        <th style="padding-left:4px;width:60px;text-align:left;line-height:40px">物料名称</th>
                                        <th style="padding-left:4px;width:60px;text-align:left;line-height:40px">一级分类</th>
                                        <th style="padding-left:4px;width:60px;text-align:left;line-height:40px">二级分类</th>
                                        <th style="padding-left:4px;width:60px;text-align:left;line-height:40px">单位</th>
                                        <th style="padding-left:4px;width:60px;text-align:left;line-height:40px">确认数量</th>
                                        <th style="padding-left:4px;width:60px;text-align:left;line-height:40px">确认小计</th>
                                        <th style="padding-left:4px;width:60px;text-align:left;line-height:40px">异议数量</th>
                                        <th style="padding-left:4px;width:60px;text-align:left;line-height:40px">异议小计</th>
                                        <th style="padding-left:4px;width:60px;text-align:left;line-height:40px">操作方</th>
                                        <th style="padding-left:4px;width:60px;text-align:left;line-height:40px">操作人</th>
                                        <th style="padding-left:4px;width:60px;text-align:left;line-height:40px">操作时间</th>
                                        <th style="padding-left:4px;width:60px;text-align:left;line-height:40px">异议备注</th>
                                    </tr>
                                    </thead>
                                    <tbody class="limiting">
                                      <tr layout="row" layout-align="start center" v-for="(item,i) in viewdetails.yy_dtls" :key="i" class="drag-list">
                                        <td style="padding-left:4px;width:60px;text-align:left;line-height:40px">{{i+1}}</td>
                                        <td style="padding-left:4px;width:60px;text-align:left;line-height:40px">{{item.n || '---'}}</td>
                                        <td style="padding-left:4px;width:60px;text-align:left;line-height:40px">{{item.moc || '---'}}</td>
                                        <td style="padding-left:4px;width:60px;text-align:left;line-height:40px">{{item.mtc || '---'}}</td>
                                        <td style="padding-left:4px;width:60px;text-align:left;line-height:40px">{{item.un || '---'}}</td>
                                        <td style="padding-left:4px;width:60px;text-align:left;line-height:40px">{{item.dc}}</td>
                                        <td style="padding-left:4px;width:60px;text-align:left;line-height:40px">{{item.da}}</td>
                                        <td style="padding-left:4px;width:60px;text-align:left;line-height:40px">{{item.yc}}</td>
                                        <td style="padding-left:4px;width:60px;text-align:left;line-height:40px">{{item.ya}}</td>
                                        <td style="padding-left:4px;width:60px;text-align:left;line-height:40px">{{item.yo || '---'}}</td>
                                        <td style="padding-left:4px;width:60px;text-align:left;line-height:40px">{{item.oen || '---'}}</td>
                                        <td style="padding-left:4px;width:60px;text-align:left;line-height:40px">{{item.ot || '---'}}</td>
                                        <td style="padding-left:4px;width:60px;text-align:left;line-height:40px">{{item.r || '-----'}}</td>
                                    </tr>
                                    </tbody>
                                </table>
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
                    <el-button type="primary" v-show="viewdetails.status == '已完成'||viewdetails.status == '待收货'" v-print="print">打印</el-button>
                    <el-button type="primary" @click="effective">类似创建</el-button>
                    <el-button type="primary" v-show="viewdetails.status == '待收货'"
                               @click="compileprinter">红冲</el-button>
                    <el-button type="primary" v-show="viewdetails.status == '待收货'" @click="noneffective">反审核</el-button>
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
                                <span class="reqfieldsd"></span>调拨单单号：
                            </div>
                            <div class="materialnr controlling">{{viewdetails.code}}</div>
                        </div>
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd"></span>出库操作员名称：
                            </div>
                            <div class="materialnr controlling">{{viewdetails.out_emp_name }}</div>
                        </div>
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd"></span>入库仓库：
                            </div>
                            <div class="materialnr controlling">{{viewdetails.in_store_name}}</div>
                        </div>
                    </div>
                    <div class="tidsesfe">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd"></span>出库仓库：
                            </div>
                            <div class="materialnr controlling">{{viewdetails.out_store_name}}</div>
                        </div>
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd"></span>出库总成本：
                            </div>
                            <div class="materialnr controlling">{{viewdetails.total_amt }}</div>
                        </div>
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd"></span>出库总售出金额：
                            </div>
                            <div class="materialnr controlling">{{viewdetails.sell_total_amt }}</div>
                        </div>
                    </div>
                    <div class="tidsesfe">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd"></span>出库时间：
                            </div>
                            <div class="materialnr controlling">{{viewdetails.out_store_time }}</div>
                        </div>
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd"></span>备注：
                            </div>
                            <div class="materialnr gaib">{{viewdetails.remark || '---'}}</div>
                        </div>
                    </div>
                </el-form>
                <div class="addmaterial">
                    <table class="zhuixiaoi">
                        <thead class="mmodity">
                        <tr>
                            <th>序号</th>
                            <th>物料名称</th>
                            <th>一级单位</th>
                            <th>二级单位</th>
                            <th>物料单位</th>
                            <th>
                                <div class="alignment">红冲前数量</div>
                            </th>
                            <th>红冲数量</th>
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
                                <el-input v-model="hcsl[i].sl" placeholder="请输出数量" ref="selectsse" class="Writmiddle"/>
                            </td>
                            <td>
                                <div class="alignment">{{item.c - hcsl[i].sl}}</div>
                            </td>
                            <td>
                                <div class="alignment">{{((item.rp/item.c) * hcsl[i].sl).toFixed(2)}}</div>
                            </td>
                            <td>
                                <div class="alignment">{{((item.sp/item.c) * hcsl[i].sl).toFixed(2)}}</div>
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
import EllipsisTooltip from '@/components/EllipsisTooltip.vue'//根据路径导入组件
import IconButton from '@/components/IconButton.vue'//根据路径导入组件
import CharactersButton from '@/components/CharactersButton.vue'//根据路径导入组件
export default {
  data(){
    return {
      Inbound: {
        date: [],//日期
        state: '0',//类型
        pagenum: 1,//第几页
        pagecnt: 1,//总页数
        rowcnt: 1,//总行数
        jlines: 5,//每页多少行
        init: 1,//是否初始化
        cklx: '',//出库仓库
        remark: '',//备注
      },//出库
      jindst: '1',//近多少天
      cklxnr: [],//出库仓库
      tableData: [],// 读取管理列表
      dialogFormVisible: false,//控制新建出库是否显示
      ProductLibrary: {
        warehousess: [],//出库仓库列表
        warehouse: '',//出库仓库
        pustorage: '',// 入库仓库
        pustorageses: [],// 入库仓库列表
        remark: '',//备注
      },//出库
      multipleSelection: [],// 选中的内容
      isIndeterminate: false,// 出库选择一部分
      checkAll: false,//出库全选
      addprincipal: false,//控制添加物料是否显示
      dimoptions: [],// 模糊查询列表

      savedata: [],//添加过数量的数据

      dimvalue: '', // 查询选中的
      loading: false, // 是否正在从远程获取数据
      checkedCitiesdim: [],//物料已选择内容
      supplies: [],//已添加的物料
      paramsPrdList: [], // 从首页传进来的商品列表
      isFirst: true, // 是否是从首页进来的数据
      checkAlladd: false,//物料全部选中触发
      checkedCitiesadd: [],//物料已选择内容
      isIndeterminateadd: false,//物料全选或者全不选
      viewdetails: {},//查看详情内容
      cfdetails: false,// 控制查看详情显示与否
      Reddashed: false,// 控制红冲显示与否
      hcsl: [],//红冲内容

      sdadgr: false,

      timer: null,//定时器

      print: {
        id: 'print',
        popTitle: '其他入库单', // 打印配置页上方标题
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
    if(this.$route.query.itemObj){
      this.paramsPrdList = JSON.parse(this.$route.query.itemObj)
      this.xingh()
      this.ProductLibrary.pustorage = this.paramsPrdList.id
      this.supplies = this.paramsPrdList.ms.map(item => ({
        a: "",
        c: "",
        dj: "",
        id: item.id,
        jg: "",
        moc: item.on,
        mtc: item.tn,
        n: item.sn,
        sl: Math.abs(item.c),
        ui: 0,
        un: item.un
      }))
    }
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
  components: {
    EllipsisTooltip,
    IconButton,
    CharactersButton
  },
  filters: {
    decimal(v){
      return v.toFixed(2)
    }
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
      var g = document.getElementsByClassName("soutd-rkrq")[0].clientHeight;
      var s = i - 48 - 60 - 55 - 70 - 70 - g;
      this.MaxHeight = s
      this.MaxNumber = Math.floor(s / 37)
    },
    // 打印
    Print(){
      myPrint(this.$refs.print);
      function myPrint(obj) {
        newWindow.print();
      }
    },
    // 根据输出的内容模糊查找
    querySearch(queryString,) {
      if (this.sdadgr) {
        if (queryString == '') {
          this.dimoptions = []
          this.savedata = []
        }
      }
      // this.loading = true;
      this.$api.ERP.soutd.requestsoutdmat_items({
        store_id: this.ProductLibrary.warehouse,
        name: queryString,
        page_num: 1,
        page_size: 9999999,
      }).then(res => {
        if (res.data) {
          for (const key in res.data || []) {
            for (const ke in this.savedata) {
              if (this.savedata[ke].sl) {
                if (res.data[key].id == this.savedata[ke].id) {
                  res.data[key].sl = this.savedata[ke].sl
                }
              }
            }
            for (const ke in this.dimoptions) {
              if (this.dimoptions[ke].sl) {
                if (res.data[key].id == this.dimoptions[ke].id) {
                  res.data[key].sl = this.dimoptions[ke].sl
                }
              }
            }
            for (const ke in this.supplies) {
              if (this.supplies[ke].sl) {
                if (res.data[key].id == this.supplies[ke].id) {
                  res.data[key].c = res.data[key].c - this.supplies[ke].sl
                }
              }
            }
          }
        }
        this.dimoptions = res.data || []
        // this.checkedCitiesdim = []

        // cb(results);
        // this.loading = false;
        // if(this.dimoptions.length==0){
        //     this.$message.warning("出库仓库没有此物料")
        // }

      })

    },
    // 使用自定义日期后取消单选框选择的
    adgg(i){
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
    // 获取管理列表内容  查询
    demand(){
      this.$api.ERP.soutd.requestsoutdlist({
        page_num: this.Inbound.pagenum,
        page_size: 10,
        status: Number(this.Inbound.state),
        begin_day: this.Inbound.date[0],
        end_day: this.Inbound.date[1],
        is_init: Number(this.Inbound.init),
        in_store_id: Number(this.Inbound.cklx) || 0,
        remark: this.Inbound.remark,
      }).then(res => {
        if (res.code == 1) {
          this.tableData = res.data.datas || []
          this.Inbound.pagecnt = res.data.page_cnt
          this.Inbound.rowcnt = res.data.row_cnt
          this.Inbound.pagenum = res.data.page_num
          this.cklxnr = res.data.stores
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
      if (val) {
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
      let checkedCount = value.length;
      this.checkAll = checkedCount === this.tableData.length;
      this.isIndeterminate = checkedCount > 0 && checkedCount < this.tableData.length;
    },
    // 当前是多少页
    handleCurrentChange(val) {
      this.Inbound.pagenum = val
      this.demand()
    },
    // 重置
    resetstorage(){
      this.Inbound.date = []
      this.Inbound.state = '0'
      this.Inbound.pagenum = 1
      this.Inbound.pagecnt = 1
      this.Inbound.rowcnt = 1
      this.Inbound.remark = ''
      this.Inbound.cklx = ''
      this.Inbound.init = 1
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
      this.ProductLibrary.pustorage = ''
      this.ProductLibrary.remark = ''
      this.supplies = []
      this.checkAlladd = false
      this.checkedCitiesadd = []
      this.isIndeterminateadd = false
      this.$api.ERP.soutd.requestsoutdstore_items().then(res => {
        this.ProductLibrary.warehousess = res.data.out_stores
        this.ProductLibrary.pustorageses = res.data.in_stores
      })
    },
    // 添加物料
    appendmaterial(){
      if (this.ProductLibrary.warehouse != "" && this.ProductLibrary.pustorage != "") {
        this.addprincipal = true
        this.dimvalue = ''

        this.querySearch('')
        this.sdadgr = true
        this.checkedCitiesdim = []
        this.edit()
      } else {
        this.$message.warning("请先选择出库仓库和入库仓库后在选择添加物料")
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
      })
    },
    // 删除选中物料
    handleClose(tag) {
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
      var s = []
      for (const key in this.savedata) {
        for (const ke in this.checkedCitiesdim) {
          if (this.savedata[key].id == this.checkedCitiesdim[ke]) {
            s.push(this.savedata[key])
          }
        }
      }
      var jxs = false
      if (s.length == 0) {
        jxs = false
        this.$message.warning("勾选的物料出库数量不能为空或零")
      }
      for (const iterator of s) {
        if ((iterator.sl !== Infinity) && !isNaN(iterator.sl)) {
          jxs = true
        } else {
          jxs = false
          this.$message.warning("勾选的物料出库数量不能为空或零")
          return;
        }
      }

      if (jxs) {
        var q = false
        var w = JSON.parse(JSON.stringify(s));
        var arr = []
        for (const key in this.supplies) {
          for (const i in s) {
            if (this.supplies[key].id == s[i].id) {
              arr.push(Number(i))
              this.supplies[key].sl = Number(s[i].sl) + Number(this.supplies[key].sl)
              this.supplies[key].jg = this.supplies[key].sl * this.supplies[key].dj
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
        if (!q) {
          for (const key in  w) {
            w[key].dj = w[key].sl * w[key].p
            w[key].jg = w[key].sl * w[key].p
          }
          for (const iterator of w) {
            this.supplies.push(iterator)
          }
        }

        this.addprincipal = false
      }
    },
    // 批量删除物料
    batchDeleteSupplies(){
      if (this.checkedCitiesadd.length == 0) {
        this.$message.warning('请选择一个在进行删除')
      } else {
        var s = []
        for (const i in this.supplies) {
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
      let checkedCount = value.length;
      this.checkAlladd = checkedCount === this.supplies.length;
      this.isIndeterminateadd = checkedCount > 0 && checkedCount < this.supplies.length;
    },
    // 调拨出库
    construction(){
      this.form_rules.map(item => this.validator(item));
      if (this.form_rule_msg_remark) return;
      if (this.ProductLibrary.warehouse == '' || this.ProductLibrary.type == '') {
        this.$message.warning('必选框不能为空')
      } else {
        var s = {
          ids: [],
          count: [],
        }
        for (const iterator of this.supplies) {
          s.ids.push(iterator.id)
          s.count.push(Number(iterator.sl))
        }
        this.$api.ERP.soutd.requestsoutdnew({
          out_store_id: this.ProductLibrary.warehouse,
          in_store_id: this.ProductLibrary.pustorage,
          remark: this.ProductLibrary.remark,
          mat_ids: s.ids,
          cnts: s.count,
        }).then(res => {
          if (res.code == 1) {
            this.$message({
              showClose: true,
              message: "操作成功",
              type: 'success'
            })
            this.dialogFormVisible = false
            this.isFirst = false
            this.demand()
          } else {
            this.$message.warning(res.msg)
          }
        })
      }
    },
    // 反审核调拨库单
    noneffective(){
      if (this.multipleSelection.length == 1) {
        this.$api.ERP.soutd.requestsoutdcs({id: this.multipleSelection[0]}).then(res => {
          if (res.code == 1) {
            this.demand()
            this.multipleSelection = []
            this.isIndeterminate = false
            this.checkAll = false
            this.$message({
              showClose: true,
              message: "操作成功",
              type: 'success'
            })
            this.multipleSelection = []
            this.isIndeterminate = false
            this.isIndeterminateadd = false
            this.cfdetails = false
          } else {
            this.$message.warning(res.msg)
          }
        })
      } else {
        this.$message.warning("请选择一个进行操作")
      }

    },
    // 读取调拨库单详情, 用于信息展示
    showviewdetails(id){
      this.multipleSelection = [id]
      this.isIndeterminate = true
      this.$api.ERP.soutd.requestsoutdget_f_view({id: id}).then(res => {
        this.viewdetails = res.data
        this.cfdetails = true
        this.hcsl = []
      })
    },
    // 读取调拨库单详情, 用于红冲
    compileprinter(){
      this.cfdetails = false
      if (this.multipleSelection.length == 1) {
        this.$api.ERP.soutd.requestsoutdget_f_hc({id: this.multipleSelection[0]}).then(res => {
          if (res.code == 1) {
            this.viewdetails = res.data || []
            this.Reddashed = true
            this.hcsl = []
            for (const key in res.data.dtls) {
              this.hcsl.push({
                sl: '',
                id: res.data.dtls[key].id
              })
            }
            this.$nextTick(() => {  //次要代码
              this.$refs.selectsse[0].focus();
            })
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
      var id = []
      var sl = []
      for (const key in this.hcsl) {
        if (this.hcsl[key].sl != 0) {
          id.push(this.hcsl[key].id)
          sl.push(Number(this.hcsl[key].sl))
        }
      }
      this.$api.ERP.soutd.requestsoutdhc({
        record_dtl_ids: id,
        cnts: sl
      }).then(res => {
        if (res.code == 1) {
          this.Reddashed = false
          this.$message({showClose: true, message: "操作成功", type: 'success'})
          this.demand()
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 类似创建
    effective(){
      this.cfdetails = false
      if (this.multipleSelection.length == 1) {
        this.$api.ERP.soutd.requestsoutdget_f_copy({id: this.multipleSelection[0]}).then(res => {

          this.ProductLibrary = {
            warehousess: res.data.out_stores,
            warehouse: res.data.out_store_id,
            pustorageses: res.data.in_stores,
            pustorage: res.data.in_store_id,
            remark: res.data.remark,
          }
          this.supplies = []
          for (const key in res.data.dtls) {
            this.supplies.push({
              id: res.data.dtls[key].id,// id
              n: res.data.dtls[key].n,// 名字
              moc: res.data.dtls[key].moc,// 一级分类
              mtc: res.data.dtls[key].mtc,// 二级分类
              ui: res.data.dtls[key].ui,// 单位名字
              un: res.data.dtls[key].un,//单位id
              c: res.data.dtls[key].c,// 数量
              a: res.data.dtls[key].sa, // 金额
              sl: res.data.dtls[key].c,  // 出库数量
            })
          }
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
    Inboundstate(){
      return JSON.parse(JSON.stringify(this.Inbound.state))
    },
    hcsls(){
      return JSON.parse(JSON.stringify(this.hcsl || {}))
    },
  },
  watch: {
    windowHeigh(val) {
      let that = this;
      this.RollMaxHeight(val)
    },
    windowWidt (val) {
      let that = this;
      this.RollMaxHeight(that.windowHeigh)
    },
    // 设置日期
    jindst: {
      deep: true,
      handler: function (after, before) {
        var now = new Date()
        var year = now.getFullYear()//年
        var month = (now.getMonth() + 1).toString().padStart(2, '0')//月
        var date = now.getDate().toString().padStart(2, '0');//日
        if (after == 1) {// 7天
          this.daterq()
          this.demand()
        } else if (after == 2) {//一个月
          now.setMonth(now.getMonth() - 1)
          var now1 = new Date(now.setMonth(now.getMonth() - 1 + 1))
          var year1 = now1.getFullYear()//年
          var month1 = (now1.getMonth() + 1).toString().padStart(2, '0')//月
          var date1 = now1.getDate().toString().padStart(2, '0');//日
          this.Inbound.date = [`${year1}-${month1}-${date1}`, `${year}-${month}-${date}`]
          this.demand()
        } else if (after == 3) {//3个月
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
    // 只能输入数字
    dimoptio: {
      deep: true,
      handler: function (after, before) {
        for (const key in after) {
          if (after[key].sl != undefined && after[key].sl != '0' && after[key].sl != '') {
            var reg = /^[0-9]*$/g
            if (after[key].sl != '' || after[key].sl != undefined) {
              var s = false
              var w = JSON.parse(JSON.stringify(this.checkedCitiesdim));
              for (const ke in this.checkedCitiesdim) {
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
                if (reg.test(after[key].sl)) {
                  if (after[key].sl > after[key].c) {
                    this.dimoptions[key].sl = after[key].c + ''
                  }
                } else {
                  this.dimoptions[key].sl = (before[key].sl || '') + ''
                }
              }
              // 判断哪个物料的数量发生变化，选中里面有的数量替换，没有添加
              if (after[key].sl != before[key].sl) {
                var s = 0
                for (const ke in this.savedata) {
                  if (this.savedata[ke]) {
                    if (after[key].id == this.savedata[ke].id) {
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
            // 删除掉数字，选中内容也删除
            if (after[key].sl == '' || after[key].sl == undefined || after[key].sl == '0') {
              for (const ke in this.savedata) {
                if (after[key].id == this.savedata[ke].id) {
                  this.savedata.splice(ke, 1)
                }
              }
              for (const ke in this.checkedCitiesdim) {
                if (after[key].id == this.checkedCitiesdim[ke]) {
                  this.checkedCitiesdim.splice(ke, 1)
                }
              }
            }
          }
        }
      }
    },
    checkedCities: {
      deep: true,
      handler: function (after, before) {
        if (after.length < before.length) {
          var s = JSON.parse(JSON.stringify(before));
          for (const key in s) {
            for (const ke in after) {
              if (after[ke] == s[key]) {
                s.splice(key, 1)
              }
            }
          }
          if (s.length == 1) {
            for (const key in this.savedata) {
              if (s[0] == this.savedata[key].id) {
                this.savedata.splice(key, 1)
              }
            }
          }

        }
        if (after.length > before.length) {
          for (const key in this.dimoptions) {
            if (this.dimoptions[key].id == after[after.length - 1]) {
              if (this.dimoptions[key].sl != '' && this.dimoptions[key].sl != undefined && this.dimoptions[key].sl != '0') {
                var s = false
                for (const ke in this.savedata) {
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
        if(this.paramsPrdList && this.isFirst) return
        for (const key in after) {
          if (after[key].sl > after[key].c) {
            this.supplies[key].sl = after[key].c
          }
          if (before[key] != undefined) {
            if (after[key].sl != before[key].sl) {
              this.supplies[key].jg = before[key].dj * after[key].sl
            }
          }
        }

      }
    },
    // 延迟搜索
    dimvalue: function (after, before) {
      if (this.timer) {
        clearTimeout(this.timer)
      }
      this.timer = setTimeout(() => {
        if (after == '') {
          this.sdadgr = false
          this.querySearch('')
        } else {
          this.querySearch(after)
        }
      }, 500)
    },
    Inboundstate: {
      deep: true,
      handler: function (after, before) {
        this.demand()
      }
    },
    // 红冲数量为数字 不能大于出库数量
    hcsls: {
      deep: true,
      handler: function (after, before) {
        if (after) {
          for (const key in after) {
            if (after[key].sl) {
              if (after[key].sl != before[key].sl) {
                var reg = /^[0-9]*$/g
                if (reg.test(after[key].sl)) {
                  if (after[key].sl > this.viewdetails.dtls[key].rc) {
                    this.hcsl[key].sl = this.viewdetails.dtls[key].rc + ''
                  }
                } else {
                  this.hcsl[key].sl = (before[key].sl || '') + ''
                }
              }
            }
          }
        }
      }
    },
    // 监听出品库
    'ProductLibrary.warehouse':{
      deep: true,
      handler(newVal){
        if(this.paramsPrdList && this.isFirst){
          this.$api.ERP.soutd.requestsoutdmat_items({
            store_id: newVal * 1,
            name: '',
            page_num: 1,
            page_size: 9999999,
          }).then(res => {
            if (res.data) {
              console.log('this.supplies',this.supplies)
              this.supplies.forEach(el => {
                const find = res.data.find(item => item.id == el.id)
                console.log(find)
                el.c = find ? find.c : ''
                el.a = find ? find.a : ''
              })
            }
          })
        }
        
      }
    }
  },

}
</script>
<style>
    /* 靠右 */
    .soutd .el-dialog {
        margin: 0px 0px 0px auto !important;
        background-color: #f9f9f9;
        height: 100%;
        position: relative;
    }

    .soutd .el-dialog__footer {
        position: absolute;
        width: 100%;
        bottom: 0;
        right: 0;
        display: flex;
        justify-content: center;
    }

    .soutd .el-dialog__body {
        padding: 0px 20px 30px 20px;
        overflow-y: scroll !important;
        width: calc(100% - 40px);
        height: calc(100% - 160px);
        max-height: calc(100% - 160px);
        margin: 0;
    }

    .soutd .el-dialog {
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .soutd {
        width: calc(100% - 40px);
        height: calc(100% - 40px);
        padding: 20px 30px;
    }

    .soutd .gaib {
        width: 500px !important;
        display: flex;
        align-items: center;
    }

    .monad, .show {
        display: none;
    }

    /* 必填 */
    .soutd .mandatory {
        color: #40404e;
        width: 140px;
        text-align: right;
        /* padding-top: 10px; */
        line-height: 40px;
    }

    .soutd .controlling {
        width: 230px !important;
        line-height: 40px;
    }

    .soutd .reqfieldsd {
        font-size: 14px;
        padding-right: 4px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* 表格无数据时展示 */
    .soutd .tiaodd {
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

    .soutd .nodata {
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        padding: 0;
    }

    .soutd .nodata img {
        width: 60px;
        height: 60px;
    }

    .soutd .nodata .hint {
        line-height: 36px;
        font-size: 13px !important;
    }

    .soutd .drag-list .nodata {
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
    }

    .soutd .drag-list .nodata img {
        width: 60px;
        height: 60px;
    }

    .soutd .drag-list .nodata .hint {
        font-size: 13px !important;
    }

    /* 全选字体大小 */
    .soutd .zhuixiaoi .mmodity .el-checkbox__label {
        font-size: 12px;
    }

    /* 表格内文字居中 */
    .soutd .alignment {
        text-align: right !important;
        padding-right: 15px;
    }

    .soutd .Writmiddle .el-input__inner {
        text-align: right;
    }

    .soutd .Writmiddle .el-input__inner::-webkit-input-placeholder {
        text-align: center;
    }

    .soutd
        /* 全选字体大小 */
    .soutd .zhuixiaoi .mmodity .el-checkbox__label {
        font-size: 12px;
    }

    /* 给一级分类二级分类加外边距和圆角 */
    .soutd .el-radio-button {
        margin-right: 6px;
        margin-bottom: 6px;
        /* overflow: hidden; */
        /* border: 1px solid #f5f5f5; */
        height: 30px;
    }

    .soutd .el-radio-button__inner {
        border-radius: 4px !important;
    }

    .soutd .container .el-radio-button__inner {
        padding: 6px 20px;
    }

    /* 去除瑕疵 */
    .soutd .el-radio-button__orig-radio:checked + .el-radio-button__inner {
        box-shadow: none
    }

    /* 选中状态颜色背景边框 */
    .soutd .el-radio-button__orig-radio:checked + .el-radio-button__inner {
        background-color: rgba(0, 0, 0, 0);
        border: 1px solid #6A9EFF !important;
        color: #6A9EFF;
    }

    /* 内容 */
    .soutd .soutd-headline {
        font-size: 30px;
        font-weight: bold;
        color: #40404e;
    }

    .soutd .soutd-controller {
        /*margin-top: 20px;*/
        height: 54px;
        width: 100%;
        background-color: #e5e5e5;
        display: flex;
        align-items: center;
    }

    .soutd .soutd-rkrq {
        width: 100%;
        color: #40404e;
        overflow: hidden;
        font-size: 13px;
        line-height: 14px;
    }

    .soutd .soutd-rkrq .rkrq {
        display: inline-flex;
        align-items: center;
        margin: 0 0 14px 0;
    }

    .soutd .soutd-rkrq .rkrq:nth-child(1) {
        width: 670px !important;
    }

    .soutd .soutd-rkrq .rkrq:nth-child(2) {
        width: 275px !important;
    }

    .soutd .soutd-rkrq .rkrq:nth-child(3) {
        width: 250px !important;
    }

    .soutd .soutd-rkrq .rkrq:nth-child(4) {
        width: 150px !important;
    }

    .soutd .soutd-rkrq .rkrq .danxk {
        height: 34px;
        margin-right: 10px;
        display: inline-flex;
        align-items: center;
    }

    .soutd .soutd-rkrq .rkrq .danxk img {
        display: inline-block;
        width: 12px;
        height: 12px;
        margin-right: 6px;
    }

    .soutd .soutd-rkrq .rkrq .danxk .el-radio-button {
        margin: 0px 4px;
        box-shadow: none !important;
    }

    .soutd .soutd-rkrq .rkrq .danxk .el-radio-button__inner {
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

    .soutd .soutd-rkrq .rkrq .danxk .el-radio-button__orig-radio:checked + .el-radio-button__inner {
        background-color: transparent !important;
        color: #2170ff;
    }

    .soutd .ewdetai {
        color: #2170ff;
        cursor: pointer;
    }

    .soutd .layouts {
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .soutd .AddPrincipal {
        color: #4eadfc
    }

    .soutd .compatibility {
        display: flex;
        align-items: center;
        margin-bottom: 10px;
    }

    .soutd .required {
        width: 60px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* 取消按钮 */
    .soutd .el-dialog .el-button--default {
        background-color: #ccc;
        border: 1px solid #ccc;
        color: #40404e;
    }

    .soutd .el-dialog {
        background-color: #f9f9f9;
    }

    .soutd .el-input__inner {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
        height: 30px;
        line-height: 30px;
    }

    .soutd .el-dialog__title, .soutd .el-dialog__headerbtn .el-dialog__close, .soutd .el-form-item__label {
        color: #1a1a21;
    }

    .soutd .el-input {
        width: 190px;
    }

    .soutd .el-form-item {
        display: flex;
        margin: 0;
    }

    .soutd .el-table th.el-table__cell.is-leaf {
        background-color: #2A2B34;
        color: #40404e;
        border-bottom: 1px solid #f5f5f5;
        border-right: 1px solid #f5f5f5;
    }

    .soutd .el-checkbox-group {
        display: flex;
        align-items: flex-end;
        justify-content: left;
    }

    .soutd .el-checkbox__input {
        background-color: rgba(0, 0, 0, 0);
    }

    .soutd .el-checkbox__input.is-disabled.is-checked .el-checkbox__inner {
        background-color: rgba(0, 0, 0, 0) !important;
    }

    .soutd .el-dialog {
        width: 30vw;
    }

    .soutd .has-gutter {
        border: 1px solid #f5f5f5;
    }

    .soutd .el-table__body:nth-of-type(odd) {
        background-color: #1A1A20;
        color: #F0F0F0;
    }

    .soutd .el-table__body:nth-of-type(even) {
        background-color: #e5e5e5;
        color: #F0F0F0;
    }

    .soutd .el-table__empty-block {
        background-color: #e5e5e5 !important;
    }

    .soutd .el-table__empty-text {
        color: #40404e;
    }

    .soutd .el-table__body tr:hover > td {
        background-color: #3C3D46 !important;
    }

    .soutd .el-table__body tr.current-row > td {
        background-color: #3C3D46 !important;
    }

    .soutd .el-table__body td.el-table__cell {
        border-bottom: 1px solid #f5f5f5;
        border-right: 1px solid #f5f5f5;
    }

    /* 选中改变颜色 */
    /* .soutd .el-table__body .success-row{
        background-color: #3C3D46 !important;
    } */
    .soutd .el-table--border, .soutd .el-table--group {
        border-top: 1px solid #f5f5f5;
        border-left: 1px solid #f5f5f5;
    }

    .soutd .el-table--border::after,
    .soutd .el-table--group::after,
    .soutd .el-table::before {
        background-color: #f5f5f5;
    }

    .soutd table thead tr th, .soutd table tbody tr td {
        height: 40px;
        font-size: 14px;
    }

    .soutd .el-table__body-wrapper.is-scrolling-none::-webkit-scrollbar {
        display: none !important;
    }

    .soutd .el-table__body-wrapper.is-scrolling-none {
        -ms-overflow-style: none;
        overflow: -moz-scrollbars-none;
        scrollbar-width: none;
    }

    .soutd .el-table__body {
        width: 100% !important;
    }

    .soutd .el-table__cell.gutter {
        display: none;
    }

    .soutd .el-table__header colgroup col:last-child {
        display: none;
    }

    /* 一级分类和二级分类文字颜色更改 */
    .soutd .stairfl {
        display: flex;
        align-items: center;
        margin: 0 0 14px 0;
        font-size: 13px;
        line-height: 14px;
    }

    .soutd .stairfl div:nth-of-type(1) {
        color: #40404e;
        margin-right: 9px;
    }

    .soutd .stairfl .stairastrict {
        height: 34px;
        display: flex;
        align-items: center;
    }

    .soutd .stairfl .container {
        height: 30px;
    }

    /* 更改单选框颜色 */
    .soutd .el-radio-button__inner {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
        border: 1px solid #f5f5f5;
        font-size: 14px;
    }

    .soutd .el-radio-button:first-child .el-radio-button__inner {
        border-left: 1px solid #f5f5f5;
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
    .soutd .el-tag {
        background-color: rgba(0, 0, 0, 0);
        margin-right: 10px;
        margin-bottom: 10px;
        color: #40404e;
    }

    .soutd .dialogFormVisible .el-dialog {
        width: 1280px;

    }

    .soutd .el-tag i {
        color: #40404e;
    }

    .soutd .tidsesfe {
        display: flex;
    }

    /* 多行文本输出框 */
    .soutd .el-textarea__inner {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
        width: 100%;
    }

    .soutd .el-input__count {
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
    .soutd .addmaterial {
        /* margin-top: 30px; */
        padding-top: 15px;
        /* border-top:2px solid #443f3f; */
    }

    .soutd .dialogFormVisible .rkrq {
        margin-top: 20px;
        height: 54px;
        width: 1240px;
        background-color: #e5e5e5;
        display: flex;
        align-items: center;
    }

    .soutd .el-textarea__inner{
      border-color: rgb(217, 217, 217);
    }

    .soutd .dialogFormVisible .zhuixiaoi {
        width: 1240px;
    }

    .soutd .dialogFormVisible .drag-list td:nth-of-type(2), .soutd .dialogFormVisible .mmodity th:nth-of-type(2) {
        width: 200px;
    }

    .soutd .dialogFormVisible .drag-list td:nth-of-type(3), .soutd .dialogFormVisible .mmodity th:nth-of-type(3) {
        width: 150px;
    }

    .soutd .dialogFormVisible .drag-list td:nth-of-type(4), .soutd .dialogFormVisible .mmodity th:nth-of-type(4) {
        width: 150px;
    }

    .soutd .dialogFormVisible .drag-list td:nth-of-type(5), .soutd .dialogFormVisible .mmodity th:nth-of-type(5) {
        width: 120px;
    }

    .soutd .dialogFormVisible .drag-list td:nth-of-type(6), .soutd .dialogFormVisible .mmodity th:nth-of-type(6) {
        width: 130px;
    }

    .soutd .dialogFormVisible .drag-list td:nth-of-type(7), .soutd .dialogFormVisible .mmodity th:nth-of-type(7) {
        width: 130px;
    }

    .soutd .dialogFormVisible .el-input-number {
        width: 100%;
    }

    /* 查看 */
    .soutd .viewdetailscls .el-dialog {
        width: 1280px;
        /* width: 80vw !important; */
        /* min-width: 520px !important;
        max-width:540px !important; */
    }

    .soutd .viewdetailscls .el-form {
        padding: 0px;
        margin: 20px;
        background-color: #eee;
        border-radius: 8px
    }

    .soutd .viewdetailscls .addmaterial {
        max-width: 1190px;
        overflow-x: scroll;
        margin-left: 20px;
    }

    /* 必填 */
    .soutd .viewdetailscls .mandatory {
        color: #40404e;
    }

    .soutd .viewdetailscls .compatibility {
        margin-bottom: 0px;
    }

    .soutd .viewdetailscls .el-form {
        padding-top: 10px;
    }

    .soutd .viewdetailscls .juz {
        display: flex;
        width: 1190px;
    }

    .soutd .viewdetailscls .juz .zhuixiaoi {
        width: 100%;
    }

    .soutd .viewdetailscls .dindan {
        color: #40404e;
        font-size: 16px;
        margin-top: 15px;
        margin-left: 20px;
    }

    .soutd .viewdetailscls .materialnr {
        width: 200px;
    }

    .soutd .viewdetailscls .materialnrs {
        width: 600px;
    }

    .soutd .viewdetailscls .materialnr, .soutd .viewdetailscls label, .soutd .viewdetailscls .materialnrs {
        color: #40404e;
        font-size: 14px;
    }

    .soutd .viewdetailscls .drag-list td:nth-of-type(1), .soutd .viewdetailscls .mmodity th:nth-of-type(1) {
        width: 50px;
    }

    .soutd .viewdetailscls .drag-list td:nth-of-type(2), .soutd .viewdetailscls .mmodity th:nth-of-type(2) {
        width: 150px;
    }

    .soutd .viewdetailscls .drag-list td:nth-of-type(3), .soutd .viewdetailscls .mmodity th:nth-of-type(3) {
        width: 130px;
    }

    .soutd .viewdetailscls .drag-list td:nth-of-type(4), .soutd .viewdetailscls .mmodity th:nth-of-type(4) {
        width: 130px;
    }

    .soutd .viewdetailscls .drag-list td:nth-of-type(5), .soutd .viewdetailscls .mmodity th:nth-of-type(5) {
        width: 100px;
    }

    .soutd .viewdetailscls .drag-list td:nth-of-type(6), .soutd .viewdetailscls .mmodity th:nth-of-type(6) {
        width: 100px;
    }

    .soutd .viewdetailscls .drag-list td:nth-of-type(7), .soutd .viewdetailscls .mmodity th:nth-of-type(7) {
        width: 100px;
    }

    .soutd .viewdetailscls .drag-list td:nth-of-type(8), .soutd .viewdetailscls .mmodity th:nth-of-type(8) {
        width: 100px;
    }

    .soutd .viewdetailscls .drag-list td:nth-of-type(9), .soutd .viewdetailscls .mmodity th:nth-of-type(9) {
        width: 100px;
    }

    .soutd .viewdetailscls .drag-list td:nth-of-type(10), .soutd .viewdetailscls .mmodity th:nth-of-type(10) {
        width: 100px;
    }

    .soutd .viewdetailscls .drag-list td:nth-of-type(11), .soutd .viewdetailscls .mmodity th:nth-of-type(11) {
        width: 140px;
    }

    .soutd .viewdetailscls .drag-list td:nth-of-type(12), .soutd .viewdetailscls .mmodity th:nth-of-type(12) {
        width: 140px;
    }

    .soutd .viewdetailscls .drag-list td:nth-of-type(13), .soutd .viewdetailscls .mmodity th:nth-of-type(13) {
        width: 120px;
    }

    /* 红冲 */
    .soutd .hcwdetailscls .el-dialog {
        width: 1280px;
    }

    .soutd .hcwdetailscls .el-form {
        padding: 0px;
        margin: 20px;
        background-color: #eee;
        border-radius: 8px
    }

    /* 必填 */
    .soutd .hcwdetailscls .mandatory {
        color: #40404e;
    }

    .soutd .hcwdetailscls .compatibility {
        margin-bottom: 0px;
    }

    .soutd .hcwdetailscls .addmaterial {
        max-width: 1190px;
        overflow-x: scroll;
        margin-left: 20px;
    }

    .soutd .hcwdetailscls .addmaterial .zhuixiaoi {
        width: 100%;
    }

    .soutd .hcwdetailscls .materialnr {
        width: 200px;
    }

    .soutd .hcwdetailscls .materialnrs {
        width: 600px;
    }

    .soutd .hcwdetailscls .el-input-number {
        width: 100%;
    }

    .soutd .hcwdetailscls .materialnr, .soutd .hcwdetailscls label, .soutd .hcwdetailscls .materialnrs {
        color: #40404e;
        font-size: 14px;
    }

    .soutd .hcwdetailscls .drag-list td:nth-of-type(2), .soutd .hcwdetailscls .mmodity th:nth-of-type(2) {
        width: 180px;
    }

    .soutd .hcwdetailscls .drag-list td:nth-of-type(3), .soutd .hcwdetailscls .mmodity th:nth-of-type(3) {
        width: 150px;
    }

    .soutd .hcwdetailscls .drag-list td:nth-of-type(4), .soutd .hcwdetailscls .mmodity th:nth-of-type(4) {
        width: 150px;
    }

    .soutd .hcwdetailscls .drag-list td:nth-of-type(5), .soutd .hcwdetailscls .mmodity th:nth-of-type(5) {
        width: 120px;
    }

    .soutd .hcwdetailscls .drag-list td:nth-of-type(6), .soutd .hcwdetailscls .mmodity th:nth-of-type(6) {
        width: 100px;
    }

    .soutd .hcwdetailscls .drag-list td:nth-of-type(7), .soutd .hcwdetailscls .mmodity th:nth-of-type(7) {
        width: 100px;
    }

    .soutd .hcwdetailscls .drag-list td:nth-of-type(8), .soutd .hcwdetailscls .mmodity th:nth-of-type(8) {
        width: 100px;
    }

    .soutd .hcwdetailscls .drag-list td:nth-of-type(9), .soutd .hcwdetailscls .mmodity th:nth-of-type(9) {
        width: 100px;
    }

    .soutd .hcwdetailscls .drag-list td:nth-of-type(10), .soutd .hcwdetailscls .mmodity th:nth-of-type(10) {
        width: 100px;
    }

    /* 添加物料 */
    /* 模糊查询 */
    /*
      ; */
    .soutd .search .zhuixiaoi .limiting {
        border-bottom: 1px solid #f5f5f5;
    }

    .soutd .search .el-dialog {
        width: 1280px;
    }

    .soutd .search .topwidth {
        width: 300px;
        margin-top: 30px;
    }

    .soutd .search .zhuixiaoi {
        width: 1240px;
        border-collapse: collapse;
        color: #40404e;
    }

    /* 物料信息 */
    .soutd .search .materialsoutformation {
        margin-top: 10px;
        padding-top: 10px;
        /* border-top:2px solid rgb(88, 88, 88) ; */
    }

    .soutd .search .materialsoutformation .information {
        color: #40404e;
        font-size: 16px;
        margin-bottom: 12px;
    }

    .soutd .search .materialsoutformation .xzrr {
        margin-left: 30px;
    }

    .soutd .search .materialsoutformation .materialnr {
        color: #40404e;
    }

    .soutd .search .materialsoutformation .protyfsfg {
        margin: 0 0 10px;
        color: #40404e;
        width: 360px;
        display: flex;
        justify-content: space-between;
    }

    .soutd .search .materialsoutformation .protyfsfg input {
        width: 230px;
    }

    .soutd .search .el-input-number {
        width: 100%;
    }

    .soutd .search .drag-list td:nth-of-type(2), .soutd .search .mmodity th:nth-of-type(2) {
        width: 300px;
    }

    .soutd .search .drag-list td:nth-of-type(3), .soutd .search .mmodity th:nth-of-type(3) {
        width: 200px;
    }

    .soutd .search .drag-list td:nth-of-type(4), .soutd .search .mmodity th:nth-of-type(4) {
        width: 150px;
    }

    .soutd .search .drag-list td:nth-of-type(5), .soutd .search .mmodity th:nth-of-type(5) {
        width: 120px;
    }

    /* 仓库列表 */
    .zsykd {
        width: 100%;
        overflow-x: scroll !important;
    }

    .soutd .zhuixiaoi {
        width: 1600px;
        border-collapse: collapse;
        color: #40404e;
    }

    .soutd .zhuixiaoi .mmodity tr th {
        height: 36px;
        line-height: 36px;
        text-align: left;
        font-weight: 600;
        padding-left: 20px;
    }
    .soutd .zhuixiaoi .mmodity tr th .el-checkbox__label {
      font-size: 14px;
      font-weight: 600;
      color: #40404e;
    }

    .soutd .zhuixiaoi .limiting .drag-list td {
        height: 36px;
        line-height: 36px;
        text-align: left;
        white-space: normal;
        word-break: break-all;
        font-weight: 400;
        padding-left: 20px;
    }

    .soutd .zhuixiaoi .limiting .drag-list {
        border-top: solid 1px #f5f5f5;
        display: block;
        /* width: calc(100% - 17px); */
        display: flex;
    }

    .soutd .zhuixiaoi .mmodity {
        width: 100%;
        display: block;
    }

    .soutd .zhuixiaoi .mmodity tr {
        background-color: #f5f5f5;
        display: flex;
    }

    .soutd .zhuixiaoi .limiting {
        border-bottom: solid 1px #f5f5f5;
        overflow-y: auto !important;
        max-height: 540px;
        display: block;
    }

    .soutd .drag-list td:nth-of-type(1), .soutd .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .soutd .mmodity th:nth-of-type(2), .soutd .drag-list td:nth-of-type(2) {
        width: 100px;
    }

    .soutd .drag-list td:nth-of-type(3), .soutd .mmodity th:nth-of-type(3) {
        width: 130px;
    }

    .soutd .drag-list td:nth-of-type(4), .soutd .mmodity th:nth-of-type(4) {
        width: 140px;
    }

    .soutd .drag-list td:nth-of-type(5), .soutd .mmodity th:nth-of-type(5) {
        width: 120px;
    }

    .soutd .drag-list td:nth-of-type(6), .soutd .mmodity th:nth-of-type(6) {
        width: 140px;
    }

    .soutd .drag-list td:nth-of-type(7), .soutd .mmodity th:nth-of-type(7) {
        width: 140px;
    }

    .soutd .drag-list td:nth-of-type(8), .soutd .mmodity th:nth-of-type(8) {
        width: 140px;
    }

    .soutd .drag-list td:nth-of-type(9), .soutd .mmodity th:nth-of-type(9) {
        width: 150px;
    }

    .s
    .soutd .drag-list:nth-of-type(odd) {
        background-color: #f9f9f9;
        color: #40404e;
    }

    .soutd .drag-list:nth-of-type(even) {
        background-color: #f5f5f5;
        color: #40404e;
    }

    .soutd .zhuixiaoi .el-checkbox__label {
        color: #40404e;
    }

    /*  */
    .soutd .zhuixiaoi .chaoguogai {
        height: 20px;
        /* text-align: center; */
        line-height: 20px;
        width: 136px;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }

    /* 日期选择器 */
    .soutd .soutd-rkrq .rkrq .el-range-editor .el-range-input {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
    }

    .soutd .soutd-rkrq .rkrq .el-date-editor .el-range-separator, .soutd .soutd-rkrq .rkrq .el-date-editor .el-range__icon {
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
    .soutd .Pagination {
        /* width: 1093px; */
        text-align: right;
        margin-top: 20px;
    }

    .soutd .Pagination .el-pagination.is-background .btn-next, .soutd .Pagination .el-pagination.is-background .btn-prev, .soutd .Pagination .el-pagination.is-background .el-pager li {
        background-color: rgba(0, 0, 0, 0);
        border: 1px solid #606266;
        color: #40404e;
    }

    .soutd .Pagination .btn-prev {
        background-color: rgba(0, 0, 0, 0);
        border: 1px solid #606266;
    }

    .soutd .Pagination .el-pagination {
        padding: 0;
    }

    .soutd .Pagination .el-pagination .btn-next .el-icon, .soutd .Pagination .el-pagination .btn-prev .el-icon {
        color: #40404e;
    }

    .soutd .Pagination .el-pagination.is-background .el-pager li:not(.disabled).active {
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

        .printsoutd .show {
            display: block;
        }

        .printsoutd .monad {
            font-weight: bold;
            display: block;
            font-size: 30px;
            margin-top: 50px;
            color: #000;
            text-align: center;
        }

        .printsoutd .tidsesfe {
            display: flex;
        }

        .printsoutd .compatibility {
            display: flex;
            align-items: center;
        }

        .printsoutd .mandatory {
            color: #000;
            width: 140px;
            text-align: right;
            /* padding-top: 10px; */
        }

        .printsoutd .controlling {
            width: 370px !important;
            line-height: 40px;
        }

        .printsoutd .reqfieldsd {
            font-size: 16px;
            padding-right: 4px;
            color: #ce4153;
            /* 文字不可选中 */
            -webkit-user-select: none;
            -moz-user-select: none;
            -ms-user-select: none;
            user-select: none;
        }

        .printsoutd .zhuixiaoi {
            overflow: hidden;
            border-collapse: collapse;
            color: #000;
        }

        .printsoutd .zhuixiaoi .mmodity tr th {
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

        .printsoutd .zhuixiaoi .mmodity th:nth-of-type(1) {
            border-left: solid 1px #f5f5f5;
        }

        .printsoutd .zhuixiaoi .limiting .drag-list td {
            height: 40px;
            line-height: 40px;
            text-align: center;
            white-space: normal;
            word-break: break-all;
            /* border: solid 1px #f5f5f5; */
            border-bottom: solid 1px #f5f5f5;
            border-right: solid 1px #f5f5f5;
        }

        .printsoutd .zhuixiaoi .limiting .drag-list td:nth-of-type(1) {
            border-left: solid 1px #f5f5f5;
        }

        .printsoutd .zhuixiaoi .limiting .drag-list {
            display: block;
            display: flex;

        }

        .printsoutd .zhuixiaoi .mmodity {
            width: 100%;
            display: block;
        }

        .printsoutd .zhuixiaoi .mmodity tr {
            display: flex;
        }

        .printsoutd .el-form-item {
            display: flex;
            margin: 0;
        }

        .printsoutd .el-dialog {
            width: 1100px;
        }

        .printsoutd .juz {
            margin-left: 20px;
        }

        .printsoutd .addmaterial .dindan {
            color: #000;
            font-size: 20px;
            margin-bottom: 20px;
        }

        .printsoutd .materialnr {
            width: 200px;
        }

        .printsoutd .materialnrs {
            width: 600px;
        }

        .printsoutd .materialnr, .printsoutd label, .printsoutd .materialnrs {
            color: #000;
            font-size: 14px;
        }

        .printsoutd .drag-list td:nth-of-type(1), .printsoutd .mmodity th:nth-of-type(1) {
            width: 70px;
        }

        .printsoutd .drag-list td:nth-of-type(2), .printsoutd .mmodity th:nth-of-type(2) {
            width: 250px;
        }

        .printsoutd .drag-list td:nth-of-type(3), .printsoutd .mmodity th:nth-of-type(3) {
            width: 180px;
        }

        .printsoutd .drag-list td:nth-of-type(4), .printsoutd .mmodity th:nth-of-type(4) {
            width: 75px;
        }

        .printsoutd .drag-list td:nth-of-type(5), .printsoutd .mmodity th:nth-of-type(5) {
            width: 80px;
        }

        .printsoutd .drag-list td:nth-of-type(6), .printsoutd .mmodity th:nth-of-type(6) {
            width: 80px;
        }

        .printsoutd .drag-list td:nth-of-type(7), .printsoutd .mmodity th:nth-of-type(7) {
            width: 80px;
        }

        .printsoutd .drag-list td:nth-of-type(8), .printsoutd .mmodity th:nth-of-type(8) {
            width: 180px;
        }

        .printsoutd .signature {
            display: flex;
            margin-top: 50px;
        }

        .printsoutd .signature > div {
            margin-left: 30px;
            display: flex;
        }

        .printsoutd .signature span {
            font-size: 20px;
        }

        .printsoutd .signature .xian {
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

    .addprincipal .el-input, .Reddashed .el-input, .addmaterial .el-input, .el-dialog .el-input {
        width: 100%;
    }

    .drag-list-check {
        /* background: rgba(39, 52, 82, .5) !important; */
    }
</style>