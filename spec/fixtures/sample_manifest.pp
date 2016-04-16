$var1 = 'test'
file{"/tmp/${var1}.txt": ensure => present, mode => '0755'}
