package com.oizys.mall.order.controller;

import com.oizys.mall.common.result.Result;
import com.oizys.mall.order.entity.Order;
import com.oizys.mall.order.service.OrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/order")
@RequiredArgsConstructor
public class OrderController {
    
    private final OrderService orderService;
    
    @GetMapping("/list")
    public Result<List<Order>> list() {
        return Result.success(orderService.list());
    }
    
    @GetMapping("/{id}")
    public Result<Order> get(@PathVariable Long id) {
        return Result.success(orderService.getById(id));
    }
    
    @PostMapping
    public Result<Boolean> create(@RequestBody Order order) {
        return Result.success(orderService.save(order));
    }
    
    @PutMapping
    public Result<Boolean> update(@RequestBody Order order) {
        return Result.success(orderService.updateById(order));
    }
    
    @DeleteMapping("/{id}")
    public Result<Boolean> delete(@PathVariable Long id) {
        return Result.success(orderService.removeById(id));
    }
}