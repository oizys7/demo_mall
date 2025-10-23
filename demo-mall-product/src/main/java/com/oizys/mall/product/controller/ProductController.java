package com.oizys.mall.product.controller;

import com.oizys.mall.common.result.Result;
import com.oizys.mall.product.entity.Product;
import com.oizys.mall.product.service.ProductService;
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
@RequestMapping("/api/product")
@RequiredArgsConstructor
@Tag(name = "商品管理", description = "商品相关的操作接口")
public class ProductController {

    private final ProductService productService;

    @GetMapping("/list")
    @Operation(summary = "获取商品列表", description = "获取所有商品的列表信息")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "成功获取商品列表",
                    content = @Content(mediaType = "application/json",
                    schema = @Schema(implementation = Product.class)))
    })
    public Result<List<Product>> list() {
        return Result.success(productService.findAll());
    }

    @GetMapping("/{id}")
    @Operation(summary = "根据ID获取商品", description = "通过商品ID获取商品的详细信息")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "成功获取商品信息",
                    content = @Content(mediaType = "application/json",
                    schema = @Schema(implementation = Product.class))),
            @ApiResponse(responseCode = "404", description = "商品不存在")
    })
    public Result<Product> get(
            @Parameter(description = "商品ID", required = true, example = "1")
            @PathVariable Long id) {
        return Result.success(productService.findById(id).orElse(null));
    }

    @PostMapping
    @Operation(summary = "创建商品", description = "创建一个新的商品")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "商品创建成功",
                    content = @Content(mediaType = "application/json",
                    schema = @Schema(implementation = Product.class))),
            @ApiResponse(responseCode = "400", description = "请求参数错误")
    })
    public Result<Product> create(
            @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    description = "商品信息", required = true,
                    content = @Content(mediaType = "application/json",
                    schema = @Schema(implementation = Product.class)))
            @RequestBody Product product) {
        return Result.success(productService.save(product));
    }

    @PutMapping
    @Operation(summary = "更新商品", description = "更新现有商品的信息")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "商品更新成功",
                    content = @Content(mediaType = "application/json",
                    schema = @Schema(implementation = Product.class))),
            @ApiResponse(responseCode = "404", description = "商品不存在"),
            @ApiResponse(responseCode = "400", description = "请求参数错误")
    })
    public Result<Product> update(
            @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    description = "更新的商品信息", required = true,
                    content = @Content(mediaType = "application/json",
                    schema = @Schema(implementation = Product.class)))
            @RequestBody Product product) {
        return Result.success(productService.save(product));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "删除商品", description = "根据ID删除指定商品")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "商品删除成功"),
            @ApiResponse(responseCode = "404", description = "商品不存在")
    })
    public Result<Void> delete(
            @Parameter(description = "要删除的商品ID", required = true, example = "1")
            @PathVariable Long id) {
        productService.deleteById(id);
        return Result.success();
    }
}