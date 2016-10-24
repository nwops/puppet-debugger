class sample_test_breakpoint(

) {

  include stdlib
  file{'/tmp/test':
    ensure => present,
  }
  range(1,5).map | $num | {
    start_repl()
  }
}
include sample_test_breakpoint