/***
* Name: Markov1
* Author: Truong Chi Quang
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Build_MarkovCA

global {
	file file_landuse_t1 <- grid_file("../includes/ht_2015.tif");
	file file_landuse_t2 <- grid_file("../includes/ht_2020.tif"); 
	//file file_color <- csv_file("../includes/landuse_color.csv",",");// mặc định có header
	list<int> lstLanduse_t1;
	list<int> lstLanduse_t2;
	map<string, float> map_markov;// map các khoá chuyển đổi của ma trận markov	
	map<int, rgb> mapLanduse_color <- [];
	geometry shape <- envelope(file_landuse_t1); 
	action set_LU_t2 {
		ask cell_landuse_t1 {
	        // Tìm ô ở bản đồ 2 có cùng vị trí cột và dòng với ô đang xét ở bản đồ 1
	        cell_landuse_t2 o_tuong_ung <- cell_landuse_t2[grid_x, grid_y];
	        if (o_tuong_ung != nil) { // Nếu ô tương ứng ở bản đồ 2 có dữ liệu
	            landuse_t2 <- o_tuong_ung.landuse;
	        } else {
	            // Nếu bản đồ 2 bị thiếu ô ở vị trí này
	            landuse_t2 <- landuse; // Giữ nguyên loại đất cũ
   			}
		}
	}
	action create_lstlanduse {
		ask cell_landuse_t1 {
			if not (landuse in lstLanduse_t1) {
				lstLanduse_t1 << landuse;
	            mapLanduse_color[landuse] <- rgb(rnd(255), rnd(255), rnd(255));
	        }
			color <- mapLanduse_color[landuse];
		}
		// tao danh sách loại dất t2
		ask cell_landuse_t2 {
			if not (landuse in lstLanduse_t2) {
			// Nếu loại đất của từng cell_dat chưa có trong danh sách thì đưa vào
			//danh sách kiểm chứng
				lstLanduse_t2 << landuse;
				if not (landuse in lstLanduse_t1) {  // nếu landuse chưa có trong danh sách loại đất của ht t1 -> thêm vào danh sách màu
	            	mapLanduse_color[landuse] <- rgb(rnd(255), rnd(255), rnd(255));
	        	}
	        }  
	        color <- mapLanduse_color[landuse];    	
		}
		lstLanduse_t1 <- lstLanduse_t1 sort_by (each);
		lstLanduse_t2 <- lstLanduse_t1 sort_by (each);
		write "In kiem tra ds_loaidat_ht1: " + lstLanduse_t1;
		write "In kiem tra ds_loaidat_ht2: " + lstLanduse_t2;
		save lstLanduse_t1 to: "../kq/ds_loaidat_ht1.csv" format: "csv"  rewrite: true;
		save lstLanduse_t2 to: "../kq/ds_loaidat_ht2.csv" format: "csv"  rewrite: true;
	}

	action create_markov {
	    // 1. Khởi tạo Map lưu số lượng chuyển đổi (Pair Loại_Cũ :: Loại_Mới) tất cả gán bằng 0
	    loop ld_row over: lstLanduse_t1 {
	        loop ld_col over: lstLanduse_t2 {
	        	string key <- string(ld_row) + "-" + string(ld_col);
	            map_markov[key] <- 0;
	        }
	    }
	    // 2. Đếm số lượng ô chuyển đổi. 
	    ask cell_landuse_t1 {
	        string key <- string(landuse) + "-"+ string(landuse_t2);
	        map_markov[key] <- map_markov[key] + 1;
	    }
	    // 3. Chuẩn bị File CSV (Ghi tiêu đề)
	    list tieude <- [0.0] + lstLanduse_t2;
	    save tieude to: "../kq/matran_markov.csv" format: "csv"  rewrite: true;
	    save tieude to: "../kq/matran_chuyendoi.csv" format: "csv"  rewrite: true;
	
	    // 4. Tính toán và lưu dữ liệu theo từng dòng
	    loop ld_row over: lstLanduse_t1 {
	        // Đếm tổng số ô của loại đất hiện tại (Sử dụng toán tử count rất trực quan)
	        int tong_o_cu <- cell_landuse_t1 count (each.landuse = ld_row);
	        //write " ld: " +ld_row + "  - soluong:" + tong_o_cu;
	        list<float> row_changes <- [float(ld_row)];
	        list<float> row_markov <- [float(ld_row)];
	        loop ld_col over: lstLanduse_t2 {
	            string key <- string(ld_row) + "-" + string(ld_col);
	            int so_luong <- int(map_markov[key]);           
	            row_changes << so_luong;
	            // Tính xác suất (Nếu tổng ô > 0 thì chia, không thì bằng 0)
	            float xac_suat <- (tong_o_cu > 0) ? (so_luong / tong_o_cu) : 0.0;
	            row_markov << (xac_suat with_precision 2);
	        }
	        // Lưu từng dòng vào file
	        save row_changes to: "../kq/matran_chuyendoi.csv" format: "csv"  rewrite: false;
	        save row_markov to: "../kq/matran_markov.csv" format: "csv"  rewrite: false;
	    }
	    write "Xử lý ma trận Markov hoàn tất!";
	}
	init {
		// Gán hiện trạng của bản đồ thứ 2 vô grid ht1
		do set_LU_t2;
		do create_lstlanduse;
		do create_markov;
	}
}

grid cell_landuse_t1 file: file_landuse_t1 control: reflex neighbors: 8 {
	int landuse <- int(grid_value);
	int landuse_t2;
	init {
	}
	action set_color {
		// Tô màu theo bảng map danh sách mã loại đất và màu
			color <- mapLanduse_color[landuse];
	}
}

grid cell_landuse_t2 file: file_landuse_t2 control: reflex neighbors: 8 {
	int landuse <- int(grid_value);
	init {
	}
	action set_color {
		color <- mapLanduse_color[landuse];
	}
}
experiment "my_GUI_xp" type: gui {
	output {
		display bandoht1 type: java2D {
			grid cell_landuse_t1;
		}
		display bandoht2 type: java2D {
			grid cell_landuse_t2;
		}
	
	}

}



//	action load_color {
//// màu đất được chuẩn bị từ file csv, màu xuất từ QGIS sang	
//		
//		
//			matrix data <- matrix(file_color);		
//			//loop on the matrix rows (skip the first header line)
//			loop i from: 1 to: data.rows -1{
//				int id <- int(data[0,i]);
//				//loop on the matrix columns
//				mapLanduse_color[id] <-   rgb(int(data[1,i]), int(data[2,i]), int(data[3,i]));				
//			}	
//			write mapLanduse_color;
//		
//	}
