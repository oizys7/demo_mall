package com.oizys.mall.user.controller;

import com.oizys.mall.common.result.Result;
import com.oizys.mall.user.entity.User;
import com.oizys.mall.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
public class UserController {
    
    private final UserService userService;
    
    @GetMapping("/list")
    public Result<List<User>> list() {
        return Result.success(userService.list());
    }
    
    @GetMapping("/{id}")
    public Result<User> get(@PathVariable Long id) {
        return Result.success(userService.getById(id));
    }
    
    @PostMapping
    public Result<Boolean> create(@RequestBody User user) {
        return Result.success(userService.save(user));
    }
    
    @PutMapping
    public Result<Boolean> update(@RequestBody User user) {
        return Result.success(userService.updateById(user));
    }
    
    @DeleteMapping("/{id}")
    public Result<Boolean> delete(@PathVariable Long id) {
        return Result.success(userService.removeById(id));
    }
}