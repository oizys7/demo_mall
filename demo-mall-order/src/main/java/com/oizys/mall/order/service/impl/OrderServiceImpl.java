package com.oizys.mall.order.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.oizys.mall.order.entity.Order;
import com.oizys.mall.order.mapper.OrderMapper;
import com.oizys.mall.order.service.OrderService;
import org.springframework.stereotype.Service;

@Service
public class OrderServiceImpl extends ServiceImpl<OrderMapper, Order> implements OrderService {
}