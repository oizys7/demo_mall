package com.oizys.mall.product.controller;

import com.oizys.mall.common.result.Result;
import com.oizys.mall.product.entity.Product;
import com.oizys.mall.product.service.ProductService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/product")
@RequiredArgsConstructor
public class ProductController {
    
    private final ProductService productService;
    
    @GetMapping("/list")
    public Result<List<Product>> list() {
        return Result.success(productService.list());
    }
    
    @GetMapping("/{id}")
    public Result<Product> get(@PathVariable Long id) {
        return Result.success(productService.getById(id));
    }
    
    @PostMapping
    public Result<Boolean> create(@RequestBody Product product) {
        return Result.success(productService.save(product));
    }
    
    @PutMapping
    public Result<Boolean> update(@RequestBody Product product) {
        return Result.success(productService.updateById(product));
    }
    
    @DeleteMapping("/{id}")
    public Result<Boolean> delete(@PathVariable Long id) {
        return Result.success(productService.removeById(id));
    }
}