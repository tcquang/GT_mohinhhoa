model Build_MarkovCA

global control: reflex {
	file file_landuse_t1 <- grid_file("../includes/ht_2015.tif");
	file file_landuse_t2 <- grid_file("../includes/ht_2020.tif"); 
	//file file_color <- csv_file("../includes/landuse_color.csv",",");// mặc định có header
	list<int> lstLanduse_t1;
	list<int> lstLanduse_t2;
	map<pair<int,int>, float> map_markov;// map các khoá chuyển đổi của ma trận markov	
	map<int, rgb> mapLanduse_color <- [];
	geometry shape <- envelope(file_landuse_t1); 
	action set_LU_t2 {
		ask cell_landuse_t1 {
			landuse_t2 <- cell_landuse_t2[self.grid_x, self.grid_y].landuse;
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
		save lstLanduse_t1 to: "../results/ds_loaidat_ht1.csv" type: "csv" rewrite: true;
		save lstLanduse_t2 to: "../results/ds_loaidat_ht2.csv" type: "csv" rewrite: true;
	}
//	action create_markov {
//		// tạo map xác suất chuyển đổi từ ma trận
//		// khởi tạo map_markov rỗng
//		loop ld_row over: lstLanduse_t1 {
//			loop ld_col over: lstLanduse_t2 {
//				string key <- string(ld_row) + "_" + string(ld_col);
//				map_markov[key] <- 0;
//			}
//		}
//		//write "Map markov:"+ map_markov;
//		// cập nhật matran markov tu file ban do
//		ask cell_landuse_t1 {
//			string key <- string(landuse) + "_" + string(landuse_t2);
//			map_markov[key] <- map_markov[key] + 1;
//		}
//		write "Map markov:" + map_markov;
//		// Chuẩn hóa map_markov : giá trị chuyển đổi chia tổng diện tích đất ở thời điểm 1
//		// tính tổng diện tích đất mỗi loại
//		list<int> slg_cell;
//		// lôp loại đất, ask cell để tính tính tổng landuse_goc 
//		loop ld over: lstLanduse_t1 {
//			int soluong_cell <- 0;
//			ask cell_landuse_t1 {
//				if landuse = ld {
//					soluong_cell <- soluong_cell + 1;
//				}
//			}
//			slg_cell << soluong_cell;
//		}
//		//diện tich các loại đất
//		write "DT cac loại đất HT1 :" + slg_cell;
//		int i <- 0;
//		list<float> data_row_mkv <- []; // dòng kiểu danh sách phần tử để lưu vào file CSV
//		list<float> data_row_changes <- [];
//		// lưu dòng đầu là các mã loại đất
//		list<float> tieude_csv <- [0] + lstLanduse_t2;
//		save tieude_csv to: "../results/matran_markov.csv" type: "csv" rewrite: true;
//		save tieude_csv to: "../results/matran_chuyendoi.csv" type: "csv" rewrite: true;
//
//		loop ld_row over: lstLanduse_t1 {
//			data_row_mkv <- []; // xóa rỗng dòng để lưu diện tích mới
//			data_row_mkv << ld_row; // đưa loại đất vào đầu của dòng
//			data_row_changes<-[];
//			data_row_changes<<ld_row;
//			loop ld_col over: lstLanduse_t2 {
//				string key <- string(ld_row) + "_" + string(ld_col);
//				data_row_changes <- data_row_changes + map_markov[key];
//				map_markov[key] <- map_markov[key]/slg_cell[i] with_precision 2; // số lượng ô chia cho tổng số ô 
//				//đưa các giá trị xác suất vào danh sách  xuất file CSV
//				data_row_mkv <- data_row_mkv + map_markov[key];
//			}
//			i <- i + 1;
//			// lưu từng dòng là một list vào file CSV
//			save data_row_changes to: "../results/matran_chuyendoi.csv" type: "csv" rewrite: false;
//			save data_row_mkv to: "../results/matran_markov.csv" type: "csv" rewrite: false;
//		}
//
//		write "Map markov chuan hoa:" + map_markov;
//		// xuất ma trận markov CSV
//	}
//	action create_markov {
//		//Cách 2
//	  // 1. Tạo map mỗi loại đất tập hợp tất cả các cell vào danh sách ứng với mỗi loại đất
//		map<int, list<cell_landuse_t1>> groups_t1 <- cell_landuse_t1 group_by (each.landuse);
//		// Tạo map ghi số lương cell mỗi loại đất T1
//		map<int, int> count_landuse_t1;
//		loop k over: groups_t1.keys {
//		    count_landuse_t1[k] <- length(groups_t1[k]);
//		}
//		// 2. Tạo map Đếm số lượng cell chuyển đổi từ T1 sang T2
//		map<pair<int,int>, list<cell_landuse_t1>> groups_trans <- cell_landuse_t1 group_by (each.landuse :: each.landuse_t2);
//		map<pair<int,int>, int> conversion_counts;
//		loop k over: groups_trans.keys {
//		    conversion_counts[k] <- length(groups_trans[k]);
//		}
//		    // Khởi tạo file CSV
//	    save ([0] + lstLanduse_t2) to: "../results/matran_markov.csv" type: "csv" rewrite: true;
//	    save ([0] + lstLanduse_t2) to: "../results/matran_chuyendoi.csv" type: "csv" rewrite: true;
//	
//	    loop ld_row over: lstLanduse_t1 {
//	        list<float> row_changes <- [float(ld_row)];
//	        list<float> row_markov <- [float(ld_row)];
//	        
//	        // Lấy tổng số cell của loại đất ld_row, nếu không có thì mặc định là 1 để tránh chia cho 0
//	//        int total_cells <- (count_landuse_t1 keys contains ld_row) ? count_landuse_t1[ld_row] : 0;
//			int total_cells <- 0;
//			if (count_landuse_t1.keys contains ld_row) {
//			    total_cells <- count_landuse_t1[ld_row];
//			}
//	        loop ld_col over: lstLanduse_t2 {
//	            pair<int,int> key_pair <- ld_row :: ld_col;
//	           // Khai báo biến count trước với giá trị mặc định là 0
//				int count <- 0;
//				
//				// Kiểm tra xem key_pair có tồn tại trong Map không
//				if (conversion_counts.keys contains key_pair) {
//				    count <- conversion_counts[key_pair];
//				} else {
//				    count <- 0;
//				}
//	          
//	            row_changes << float(count);
//	            
//	            // Tính xác suất Markov
//	            float prob <- (total_cells > 0) ? (count / total_cells) : 0.0;
//	            row_markov << (prob with_precision 2);
//	        }
//	
//	        save row_changes to: "../results/matran_chuyendoi.csv" type: "csv" rewrite: false;
//	        save row_markov to: "../results/matran_markov.csv" type: "csv" rewrite: false;
//	    }
//	    write "Xong! File đã được lưu tại thư mục results.";
//	}
	action create_markov {
	    // 1. Khởi tạo Map lưu số lượng chuyển đổi (Pair Loại_Cũ :: Loại_Mới) tất cả gán bằng 0
	    loop ld_row over: lstLanduse_t1 {
	        loop ld_col over: lstLanduse_t2 {
	            map_markov[ld_row :: ld_col] <- 0;
	        }
	    }
	
	    // 2. Đếm số lượng ô chuyển đổi
	    ask cell_landuse_t1 {
	        pair key <- landuse :: landuse_t2;
	        map_markov[key] <- map_markov[key] + 1;
	    }
	
	    // 3. Chuẩn bị File CSV (Ghi tiêu đề)
	    list tieude <- [0] + lstLanduse_t2;
	    save tieude to: "../results/matran_markov.csv" type: "csv" rewrite: true;
	    save tieude to: "../results/matran_chuyendoi.csv" type: "csv" rewrite: true;
	
	    // 4. Tính toán và lưu dữ liệu theo từng dòng
	    loop ld_row over: lstLanduse_t1 {
	        // Đếm tổng số ô của loại đất hiện tại (Sử dụng toán tử count rất trực quan)
	        int tong_o_cu <- cell_landuse_t1 count (each.landuse = ld_row);
	        
	        list row_changes <- [ld_row];
	        list row_markov <- [ld_row];
	
	        loop ld_col over: lstLanduse_t2 {
	            int so_luong <- int(map_markov[ld_row :: ld_col]);
	            row_changes << so_luong;
	            
	            // Tính xác suất (Nếu tổng ô > 0 thì chia, không thì bằng 0)
	            float xac_suat <- (tong_o_cu > 0) ? (so_luong / tong_o_cu) : 0.0;
	            row_markov << (xac_suat with_precision 2);
	        }
	
	        // Lưu từng dòng vào file
	        save row_changes to: "../results/matran_chuyendoi.csv" type: "csv" rewrite: false;
	        save row_markov to: "../results/matran_markov.csv" type: "csv" rewrite: false;
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
