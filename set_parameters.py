rospy.set_param('a_string', 'hello')
rospy.set_param('~private_int', '9')
rospy.set_param('list_of_floats', "[1., 2., 3., 4.]")
rospy.set_param('bool_True', "true")
rospy.set_param('gains', "{'f': 1, 'l': 2, 's': 3}")

rospy.set_param_raw('a_string', 'hello')
rospy.set_param_raw('~private_int', '9')
rospy.set_param_raw('list_of_floats', "[1., 2., 3., 4.]")
rospy.set_param_raw('bool_True', True)
rospy.set_param_raw('gains', {'f': 1, 'l': 2, 's': 3})

rospy.get_param('gains/P')
