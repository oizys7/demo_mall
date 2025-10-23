package com.oizys.mall.user.controller;

import com.oizys.mall.common.result.Result;
import com.oizys.mall.user.entity.User;
import com.oizys.mall.user.service.UserService;
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
@RequestMapping("/api/user")
@RequiredArgsConstructor
@Tag(name = "用户管理", description = "用户相关的操作接口")
public class UserController {

    private final UserService userService;

    @GetMapping("/list")
    @Operation(summary = "获取用户列表", description = "获取所有用户的列表信息")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "成功获取用户列表",
                    content = @Content(mediaType = "application/json",
                    schema = @Schema(implementation = User.class)))
    })
    public Result<List<User>> list() {
        return Result.success(userService.findAll());
    }

    @GetMapping("/{id}")
    @Operation(summary = "根据ID获取用户", description = "通过用户ID获取用户的详细信息")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "成功获取用户信息",
                    content = @Content(mediaType = "application/json",
                    schema = @Schema(implementation = User.class))),
            @ApiResponse(responseCode = "404", description = "用户不存在")
    })
    public Result<User> get(
            @Parameter(description = "用户ID", required = true, example = "1")
            @PathVariable Long id) {
        return Result.success(userService.findById(id).orElse(null));
    }

    @PostMapping
    @Operation(summary = "创建用户", description = "创建一个新的用户")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "用户创建成功",
                    content = @Content(mediaType = "application/json",
                    schema = @Schema(implementation = User.class))),
            @ApiResponse(responseCode = "400", description = "请求参数错误")
    })
    public Result<User> create(
            @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    description = "用户信息", required = true,
                    content = @Content(mediaType = "application/json",
                    schema = @Schema(implementation = User.class)))
            @RequestBody User user) {
        return Result.success(userService.save(user));
    }

    @PutMapping
    @Operation(summary = "更新用户", description = "更新现有用户的信息")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "用户更新成功",
                    content = @Content(mediaType = "application/json",
                    schema = @Schema(implementation = User.class))),
            @ApiResponse(responseCode = "404", description = "用户不存在"),
            @ApiResponse(responseCode = "400", description = "请求参数错误")
    })
    public Result<User> update(
            @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    description = "更新的用户信息", required = true,
                    content = @Content(mediaType = "application/json",
                    schema = @Schema(implementation = User.class)))
            @RequestBody User user) {
        return Result.success(userService.save(user));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "删除用户", description = "根据ID删除指定用户")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "用户删除成功"),
            @ApiResponse(responseCode = "404", description = "用户不存在")
    })
    public Result<Void> delete(
            @Parameter(description = "要删除的用户ID", required = true, example = "1")
            @PathVariable Long id) {
        userService.deleteById(id);
        return Result.success();
    }
}