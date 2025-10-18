package com.oizys.mall.product.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.oizys.mall.product.entity.Product;
import com.oizys.mall.product.mapper.ProductMapper;
import com.oizys.mall.product.service.ProductService;
import org.springframework.stereotype.Service;

@Service
public class ProductServiceImpl extends ServiceImpl<ProductMapper, Product> implements ProductService {
}