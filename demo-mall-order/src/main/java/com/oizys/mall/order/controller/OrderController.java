package com.oizys.mall.order.controller;

import com.oizys.mall.common.result.Result;
import com.oizys.mall.order.entity.Order;
import com.oizys.mall.order.service.OrderService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/order")
@RequiredArgsConstructor
@Tag(name = "订单管理", description = "订单相关的操作接口")
public class OrderController {

    private final OrderService orderService;

    @GetMapping("/list")
    @Operation(summary = "获取订单列表", description = "获取所有订单的列表信息")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "成功获取订单列表",
                    content = @Content(mediaType = "application/json",
                    schema = @Schema(implementation = Order.class)))
    })
    public Result<List<Order>> list() {
        return Result.success(orderService.findAll());
    }

    @GetMapping("/{id}")
    @Operation(summary = "根据ID获取订单", description = "通过订单ID获取订单的详细信息")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "成功获取订单信息",
                    content = @Content(mediaType = "application/json",
                    schema = @Schema(implementation = Order.class))),
            @ApiResponse(responseCode = "404", description = "订单不存在")
    })
    public Result<Order> get(
            @Parameter(description = "订单ID", required = true, example = "1")
            @PathVariable Long id) {
        return Result.success(orderService.findById(id).orElse(null));
    }

    @PostMapping
    @Operation(summary = "创建订单", description = "创建一个新的订单")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "订单创建成功",
                    content = @Content(mediaType = "application/json",
                    schema = @Schema(implementation = Order.class))),
            @ApiResponse(responseCode = "400", description = "请求参数错误")
    })
    public Result<Order> create(
            @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    description = "订单信息", required = true,
                    content = @Content(mediaType = "application/json",
                    schema = @Schema(implementation = Order.class)))
            @RequestBody Order order) {
        return Result.success(orderService.save(order));
    }

    @PutMapping
    @Operation(summary = "更新订单", description = "更新现有订单的信息")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "订单更新成功",
                    content = @Content(mediaType = "application/json",
                    schema = @Schema(implementation = Order.class))),
            @ApiResponse(responseCode = "404", description = "订单不存在"),
            @ApiResponse(responseCode = "400", description = "请求参数错误")
    })
    public Result<Order> update(
            @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    description = "更新的订单信息", required = true,
                    content = @Content(mediaType = "application/json",
                    schema = @Schema(implementation = Order.class)))
            @RequestBody Order order) {
        return Result.success(orderService.save(order));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "删除订单", description = "根据ID删除指定订单")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "订单删除成功"),
            @ApiResponse(responseCode = "404", description = "订单不存在")
    })
    public Result<Void> delete(
            @Parameter(description = "要删除的订单ID", required = true, example = "1")
            @PathVariable Long id) {
        orderService.deleteById(id);
        return Result.success();
    }
}