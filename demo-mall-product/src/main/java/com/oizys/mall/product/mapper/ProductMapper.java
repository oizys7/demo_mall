package com.oizys.mall.product.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.oizys.mall.product.entity.Product;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface ProductMapper extends BaseMapper<Product> {
}